require 'rest_client'

module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible view REST API.
  class RestNode < Node

    # Name of cookie that represents a session.
    SESSION_COOKIE_NAME = 'OSESSIONID'

    attr_reader :ssl

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
    # Initializes a long life connection with credentials and session ID
    # after successful connect.
    def post_connect(user, password, http_response)
      raise NotImplementedError, 'this should be overridden by subclass'

# excon
#      cookies = CGI::Cookie::parse(http_response.headers['Set-Cookie'])
#      @session_id = cookies[SESSION_COOKIE_NAME][0]
    end


    ###
    # Sends an one-off request to the remote server.
    def oo_request(options)
      raise NotImplementedError, 'this should be overridden by subclass'
    end


    ###
    # Sends a request to the remote server
    # based on a connection object which is reusable across multiple requests.
    def request(options)
      raise NotImplementedError, 'this should be overridden by subclass'
    end


    ###
    # Gets value of the Basic Auth header.
    def basic_auth_header(user, password)
      b64 = Base64.encode64("#{user}:#{password}").delete("\r\n")
      "Basic #{b64}"
    end


# excon   ###
#    # Get request headers prepared with session ID and Basic Auth.
#    def headers
#      {'Authorization' => @basic_auth, 'Cookie' => "#{SESSION_COOKIE_NAME}=#{session_id}"}
#    end

# excon   ###
#    # Gets a connection object which is reusable across multiple requests.
#    def connection
#      @connection = Excon.new(url) if @connection.nil?
#      @connection
#    end

  end

end
