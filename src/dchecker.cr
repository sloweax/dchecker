require "./whoisclient"
require "./domain"
require "./whoisresponse"
require "./whoisservers"
require "option_parser"
require "colorize"

module DChecker
  VERSION = "0.1.2"

  timeout = 5.0
  fin = STDIN
  interval = 0.5
  FOUT = STDOUT
  OUT_TTY = FOUT.tty?
  dynamic_server = Array(String).new
  dynamic_available_regex = Array(Regex).new
  dynamic_tlds = Array(Array(String)).new
  dynamic_query = Array(String).new

  begin
    OptionParser.parse do |parser|
      parser.banner = "usage: #{PROGRAM_NAME} [options]"

      parser.on("-h", "--help", "usage helper") {
        puts parser
        puts "examples:"
        puts "    add WHOIS server for .example tld:"
        puts "        #{PROGRAM_NAME} -S whois.example -T example -R 'Found domain'"
        puts "    add multiple WHOIS servers (the second will listen for .ab and .com.ab tlds):"
        puts "        #{PROGRAM_NAME} -S whois.example -T example -R 'Found domain' -S whois.com.ab -T com.ab -T ab -R '^NOT FOUND'"
        exit
      }

      parser.on("-v", "--version", "shows program version") {
        puts VERSION
        exit
      }

      parser.on("-t seconds", "--timeout seconds", "WHOIS request timeout") { |t| timeout = t.to_f }

      parser.on("-I seconds", "--interval seconds", "min interval between WHOIS requests per server") { |i| interval = i.to_f }

      parser.on("-i FILE", "--input FILE", "reads domains from FILE") { |f| fin = File.open(f) }

      parser.on("-S server", "add WHOIS server (needs -T and -R. -Q is optional)") { |s|
        dynamic_server << s
        dynamic_query << "%domain%\n"
      }

      parser.on("-T tld", "add tld to WHOIS server") { |t|
        dynamic_tlds << Array(String).new if dynamic_server.size - 1 == dynamic_tlds.size
        dynamic_tlds[dynamic_server.size - 1] << t
      }

      parser.on("-R regex", "if the WHOIS server response matches with regex, mark it as an available domain") { |r| dynamic_available_regex << Regex.new(r, Regex::Options::MULTILINE) }

      parser.on("-Q query", "changes WHOIS query format (default: \"%domain%\\n\")") { |q|
        q = q.sub("\\n", "\n")
        dynamic_query[dynamic_server.size - 1] = q
      }

      parser.on("-X", "clear all pre-configured WHOIS servers") { SERVERS.clear }

      parser.on("-D tld", "removes pre-configured WHOIS servers for specified tld") { |t|
        SERVERS.each do |k, v|
          tlds, regex, query = v
          SERVERS[k][0].delete t
        end
      }

      parser.invalid_option do |flag|
        STDERR.puts "#{flag} is not a valid option."
        STDERR.puts parser
        exit(1)
      end

      parser.missing_option do |flag|
        STDERR.puts "#{flag} is missing a value."
        STDERR.puts parser
        exit(1)
      end
    end
  rescue err
    STDERR.puts err.message
    exit(1)
  end

  begin
    dynamic_server.zip(dynamic_tlds, dynamic_available_regex, dynamic_query).each do |h, t, r, q|
      SERVERS[h] = {t, r, q}
    end
  rescue
    STDERR.puts "could not add WHOIS server"
    exit(1)
  end

  Colorize.enabled = false unless OUT_TTY

  ochannel = Channel(WHOISResponse).new

  tld2client = Hash(String, NamedTuple(clients: Array(WHOISClient), channel: Channel(Domain))).new

  SERVERS.each do |(server, data)|
    tlds, regex, query = data

    tlds.each do |tld|
      tld2client[tld] = {clients: Array(WHOISClient).new, channel: Channel(Domain).new} unless tld2client.has_key? tld
    end

    WHOISClient.new(server, available_regex: regex, query_format: query).tap do |c|
      tlds.each do |tld|
        tld2client[tld][:clients] << c
        c.add_input_channel(tld2client[tld][:channel])
      end
      c.scan_loop(ochannel, timeout: timeout, interval: interval)
    end
  end

  domains = Array(Domain).new

  fin.each_line do |line|
    line = line.strip
    domain = Domain.parse line
    next unless domain
    next unless tld2client.has_key? domain.tld
    domains << domain
  end

  spawn do
    domains.each do |domain|
      tld2client[domain.tld][:channel].send domain
    end
  end

  domains.size.times do
    d = ochannel.receive

    unless d.success
      STDERR.puts "#{d.domain.root.colorize(:red)}\t#{d.whois_server}"
      next
    end

    if d.available
      FOUT.puts d.domain.root.colorize(:green)
    elsif OUT_TTY
      FOUT.puts d.domain.root.colorize(:yellow)
    end
  end
end
