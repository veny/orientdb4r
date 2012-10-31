require 'excon'

module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible view REST API and 'excon' library on the client side.
  class ExconNode < RestNode

    attr_accessor :proxy

    def request(options) #:nodoc:
      verify_options(options, {:user => :mandatory, :password => :mandatory, \
          :uri => :mandatory, :method => :mandatory, :content_type => :optional, :data => :optional})

      opts = options.clone # if not cloned we change original hash map that cannot be used more with load balancing

      # Auth + Cookie + Content-Type
      opts[:headers] = headers(opts)
      opts.delete :user
      opts.delete :password

      opts[:body] = opts[:data] if opts.include? :data # just other naming convention
      opts.delete :data
      opts[:path] = opts[:uri] if opts.include? :uri   # just other naming convention
      opts.delete :uri

      was_ok = false
      begin
        response = connection.request opts
        was_ok = (2 == (response.status / 100))

        # store session ID if received to reuse in next request
        cookies = CGI::Cookie::parse(response.headers['Set-Cookie'])
        sessid = cookies[SESSION_COOKIE_NAME][0]
        if session_id != sessid
          @session_id = sessid
          Orientdb4r::logger.debug "new session id: #{session_id}"
        end

        def response.code
          status
        end

      rescue Excon::Errors::SocketError
        raise NodeError
      end

      # this is workaround for a strange behavior:
      # excon delivered magic response status '1' when previous request was not 20x
      unless was_ok
        connection.reset
        Orientdb4r::logger.debug 'response code not 20x -> connection reset'
      end

      response
    end


    def post_connect(user, password, http_response) #:nodoc:

      cookies = CGI::Cookie::parse(http_response.headers['Set-Cookie'])
      @session_id = cookies[SESSION_COOKIE_NAME][0]

    end


    def cleanup #:nodoc:
      super
      connection.reset
      @connection = nil
    end


    # ---------------------------------------------------------- Assistant Stuff

    private

      ###
      # Gets Excon connection.
      def connection
        return @connection unless @connection.nil?

        options = {}
        options[:proxy] = proxy unless proxy.nil?

        @connection ||= Excon::Connection.new(url, options)
        #:read_timeout => self.class.read_timeout,
        #:write_timeout => self.class.write_timeout,
        #:connect_timeout => self.class.connect_timeout
      end

      ###
      # Get request headers prepared with session ID and Basic Auth.
      def headers(options)
        rslt = {'Authorization' => basic_auth_header(options[:user], options[:password])}
        rslt['Cookie'] = "#{SESSION_COOKIE_NAME}=#{session_id}" unless session_id.nil?
        rslt['Content-Type'] = options[:content_type] if options.include? :content_type
        rslt['User-Agent'] = user_agent unless user_agent.nil?
        rslt
      end

      ###
      # Gets value of the Basic Auth header.
      def basic_auth_header(user, password)
        b64 = Base64.encode64("#{user}:#{password}").delete("\r\n")
        "Basic #{b64}"
      end

  end

end
