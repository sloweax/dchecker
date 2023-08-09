require "socket"
require "./domain"
require "./whoisresponse"

module DChecker
  class WHOISClient
    def initialize (
      @host : String,
      @port : Int32 = 43,
      @query_format : String = "%domain%\n",
      @available_regex : Regex = /^NOT FOUND/im,
    )
      @channel = Channel(Domain).new
    end

    def check(domain : Domain, timeout : Float64 = 10) : WHOISResponse
      socket = TCPSocket.new(@host, @port, dns_timeout = timeout, connect_timeout = timeout)
      query = @query_format.sub("%domain%", domain.root)
      socket.print(query)

      response = socket.gets_to_end

      socket.close

      available = !(response =~ @available_regex).nil?

      WHOISResponse.new(domain, @host, success: true, available: available)
    end

    def scan_loop(ochannel : Channel(WHOISResponse), interval : Float64 = 0.25, timeout : Float64 = 10)
      spawn do
        loop do
          domain = @channel.receive

          spawn do
            begin
              dinfo = check(domain, timeout)
            rescue
              dinfo = WHOISResponse.new(domain, @host, success: false)
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
