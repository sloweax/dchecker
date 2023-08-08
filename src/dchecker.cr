require "./whoisclient"
require "./domain"
require "./whoisservers"
require "colorize"

module DChecker
  VERSION = "0.1.1"

  FIN = STDIN
  FOUT = STDOUT
  OUT_TTY = FOUT.tty?

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
      c.scan_loop(ochannel)
    end
  end

  domains = Array(Domain).new

  FIN.each_line do |line|
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
