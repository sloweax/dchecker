module DChecker
  SERVERS = {
    "whois.verisign-grs.com" => {["com", "net"], /^No match for/m},
    "ccwhois.verisign-grs.com" => {["cc"], /^No match for/m},
    "whois.cnnic.cn" => {["cn"], /^No matching record/m},
    "whois.gg" => {["gg"], /^NOT FOUND/m},
    "whois.tcinet.ru" => {["ru"], /^No entries found/m},
    "whois.ax" => {["ax"], /^Domain not found/m},
  }
end
