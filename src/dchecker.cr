require "./whoisclient"
require "./domain"
require "colorize"

module DChecker
  VERSION = "0.1.1"

  ochannel = Channel(DomainInfo).new

  tld2client = Hash(String, NamedTuple(clients: Array(WHOISClient), channel: Channel(Domain))).new

  [
    "com", "net", "cc", "cn", "gg", "ru"
  ].each do |tld|
    tld2client[tld] = {clients: Array(WHOISClient).new, channel: Channel(Domain).new}
  end

  WHOISClient.new("whois.verisign-grs.com", available_regex: /No match for/m).tap do |c|
    tld2client["com"][:clients] << c
    tld2client["net"][:clients] << c
  end
  tld2client["cc"][:clients] << WHOISClient.new("ccwhois.verisign-grs.com", available_regex: /No match for/m)
  tld2client["cn"][:clients] << WHOISClient.new("whois.cnnic.cn", available_regex: /^No matching record/m)
  tld2client["gg"][:clients] << WHOISClient.new("whois.gg", available_regex: /^NOT FOUND/m)
  tld2client["ru"][:clients] << WHOISClient.new("whois.tcinet.ru", available_regex: /^No entries found/m)

  tld2client.each_value do |h|
    h[:clients].each do |c|
      c.bind(h[:channel], ochannel)
    end
  end

  domains = Array(Domain).new

  STDIN.each_line do |line|
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

  out_tty = STDOUT.tty?

  domains.size.times do
    d = ochannel.receive

    unless out_tty
      puts d.domain.root if d.available
      next
    end

    color = d.available ? :green : :yellow
    color = :red unless d.success

    puts d.domain.root.colorize(color)
  end
end
