module DChecker
  SERVERS = {
    "whois.verisign-grs.com" => {["com", "net"], /^No match for/m},
    "whois.crsnic.net" => {["com"], /^No match for/m},
    "whois.opensrs.net" => {["com", "net"], /^Can't get information on non-local domain/m},
    "ccwhois.verisign-grs.com" => {["cc"], /^No match for/m},
    "whois.cnnic.cn" => {["cn"], /^No matching record/m},
    "whois.gg" => {["gg"], /^NOT FOUND/m},
    "whois.tcinet.ru" => {["ru"], /^No entries found/m},
    "whois.ax" => {["ax"], /^Domain not found/m},
    "whois.audns.net.au" => {["au"], /^NOT FOUND/m},
    "whois.dns.be" => {["be"], /Status:	AVAILABLE/m},
    "whois.nic.br" => {["br", "com.br"], /^% No match for/m},
    "whois.kr" => {["kr"], /^The requested domain was not found/m},
    "whois.jprs.jp" => {["jp"], /^No match!!/m},
    "whois.nic.it" => {["it"], /^Status: +AVAILABLE/m},
  }
end
