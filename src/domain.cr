require "uri"

module DChecker
  class Domain
    getter root : String, tld : String

    def initialize(@root, @tld)
    end

    def self.parse(domain : String)
      return nil unless domain =~ /\w+\.\w+/

      if domain =~ /^\w+:\/\//
        domain = URI.parse(domain).host
        return nil if domain.nil?
      end

      root = domain
      tld = domain.split(".")[1..].join(".")

      Domain.new(root, tld)
    end
  end
end
