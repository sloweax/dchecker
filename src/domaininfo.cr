require "./domain"

module DChecker
  struct DomainInfo
    property available, domain, success, whois_server

    def initialize(@domain : Domain, @available : Bool, @success : Bool, @whois_server : String)
    end
  end
end
