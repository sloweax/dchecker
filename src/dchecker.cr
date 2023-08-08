require "./whoisclient"
require "./domain"
require "./whoisservers"
require "option_parser"
require "colorize"

module DChecker
  VERSION = "0.1.1"

  timeout = 5.0
  fin = STDIN
  interval = 0.5
  FOUT = STDOUT
  OUT_TTY = FOUT.tty?

  OptionParser.parse do |parser|
    parser.banner = "usage: #{PROGRAM_NAME} [options]"

    parser.on("-h", "--help", "usage helper") {
      puts parser
      exit
    }

    parser.on("-v", "--version", "shows program version") {
      puts VERSION
      exit
    }

    parser.on("-t seconds", "--timeout seconds", "WHOIS request timeout") { |t| timeout = t.to_f }

    parser.on("-I seconds", "--interval seconds", "min interval between WHOIS requests per server") { |i| interval = i.to_f }

    parser.on("-i FILE", "--input FILE", "reads domains from FILE") { |f| fin = File.open(f) }

    parser.invalid_option do |flag|
      STDERR.puts "#{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  Colorize.enabled = false unless OUT_TTY

  ochannel = Channel(DomainInfo).new

  tld2client = Hash(String, NamedTuple(clients: Array(WHOISClient), channel: Channel(Domain))).new

  SERVERS.each do |(server, data)|
    tlds, regex = data

    tlds.each do |tld|
      tld2client[tld] = {clients: Array(WHOISClient).new, channel: Channel(Domain).new} unless tld2client.has_key? tld
    end

    WHOISClient.new(server, available_regex: regex).tap do |c|
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
      STDERR.puts d.domain.root.colorize(:red)
      next
    end

    if d.available
      FOUT.puts d.domain.root.colorize(:green)
    elsif OUT_TTY
      FOUT.puts d.domain.root.colorize(:yellow)
    end
  end
end
