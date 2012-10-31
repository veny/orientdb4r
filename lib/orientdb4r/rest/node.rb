module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible view REST API.
  class RestNode < Node

    # Name of cookie that represents a session.
    SESSION_COOKIE_NAME = 'OSESSIONID'

    attr_reader :ssl
    # HTTP header 'User-Agent'
    attr_accessor :user_agent

    ###
    # Constructor.
    def initialize(host, port, ssl)
      super(host, port)
      raise ArgumentError, 'ssl flag cannot be blank' if blank?(ssl)
      @ssl = ssl
    end


    def url #:nodoc:
      "http#{'s' if ssl}://#{host}:#{port}"
    end


    # ----------------------------------------------------------- RestNode Stuff


    ###
    # Sends a HTTP request to the remote server.
    # Use following if possible:
    # * session_id
    # * Keep-Alive (if possible)
    def request(options)
      raise NotImplementedError, 'this should be overridden by subclass'
    end

  end

end
