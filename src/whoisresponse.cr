require "./domain"

module DChecker
  class WHOISResponse
    getter domain : Domain
    getter whois_server : String
    getter success : Bool
    getter available : Bool

    def initialize(@domain, @whois_server, @success, @available = false)
    end
  end
end
