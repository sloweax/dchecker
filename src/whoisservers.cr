module DChecker
  SERVERS = {
    "whois.verisign-grs.com" => {["com", "net"], /^No match for/m, "%domain%\n"},
    "whois.crsnic.net" => {["com"], /^No match for/m, "%domain%\n"},
    "whois.opensrs.net" => {["com", "net"], /^Can't get information on non-local domain/m, "%domain%\n"},
    "ccwhois.verisign-grs.com" => {["cc"], /^No match for/m, "%domain%\n"},
    "whois.cnnic.cn" => {["cn"], /^No matching record/m, "%domain%\n"},
    "whois.gg" => {["gg"], /^NOT FOUND/m, "%domain%\n"},
    "whois.tcinet.ru" => {["ru"], /^No entries found/m, "%domain%\n"},
    "whois.ax" => {["ax"], /^Domain not found/m, "%domain%\n"},
    "whois.audns.net.au" => {["au"], /^NOT FOUND/m, "%domain%\n"},
    "whois.dns.be" => {["be"], /Status:	AVAILABLE/m, "%domain%\n"},
    "whois.nic.br" => {["br", "com.br"], /^% No match for/m, "%domain%\n"},
    "whois.kr" => {["kr"], /^The requested domain was not found/m, "%domain%\n"},
    "whois.jprs.jp" => {["jp"], /^No match!!/m, "%domain%\n"},
    "whois.nic.it" => {["it"], /^Status: +AVAILABLE/m, "%domain%\n"},
  }
end
