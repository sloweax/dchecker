require "socket"
require "./domain"

module DChecker
  struct DomainInfo
    property available, domain, success

    def initialize(@domain : Domain, @available : Bool, @success : Bool)
    end
  end
  

  class WHOISClient
    def initialize (
      @host : String,
      @port : Int32 = 43,
      @query_format : String = "%domain%\n",
      @available_regex : Regex = /^NOT FOUND/im,
    )
      @channel = Channel(Domain).new
    end

    def check(domain : Domain) : DomainInfo
      socket = TCPSocket.new(@host, @port, dns_timeout = 10, connect_timeout = 10)
      query = @query_format.sub("%domain%", domain.root)
      socket.print(query)

      response = socket.gets_to_end

      socket.close

      available = !(response =~ @available_regex).nil?

      DomainInfo.new(domain, available, true)
    end

    def scan_loop(ochannel : Channel(DomainInfo), interval : Float64 = 0.25)
      spawn do
        loop do
          domain = @channel.receive

          spawn do
            begin
              dinfo = check(domain)
            rescue
              dinfo = DomainInfo.new(domain, false, false)
            end

            ochannel.send dinfo
          end

          sleep interval
        end
      end
    end

    def add_input_channel(channel : Channel(Domain))
      spawn do
        loop do
          domain = channel.receive
          @channel.send domain
        end
      end
    end
  end
end
