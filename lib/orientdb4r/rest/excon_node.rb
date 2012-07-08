#require 'excon'

module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible view REST API and 'excon' library on the client side.
  class ExconNode < RestNode


    def oo_request(options) #:nodoc:
      address = "#{url}/#{options[:uri]}"
      headers = {}
      headers['Authorization'] = basic_auth_header(options[:user], options[:password]) if options.include?(:user)
      headers['Cookie'] = "#{SESSION_COOKIE_NAME}=#{session_id}" unless session_id.nil?
      response = ::Excon.send options[:method].to_sym, address, :headers => headers

      def response.code
        status
      end

      response
    end


    def request(options) #:nodoc:
      raise OrientdbError, 'long life connection not initialized' if @connection.nil?

#      data = options[:data]
#      options.delete :data
#      data = '' if data.nil? and :post == options[:method] # POST has to have data
#      begin
        # e.g. connection.request(:method => :get, :path => path, :query => {})
#        if data.nil?
          response = @connection.request(:method => options[:method], :path => options[:uri])
#        else
#          response = @resource[options[:uri]].send options[:method].to_sym, data
#        end
#      rescue
#        # fake the response object
#        response = "401 Unauthorized"
#        def response.code
#          401
#        end
#      end

      def response.code
        status
      end

      response
    end


    def post_connect(user, password, http_response) #:nodoc:
      @basic_auth = basic_auth_header(user, password)

      cookies = CGI::Cookie::parse(http_response.headers['Set-Cookie'])
      @session_id = cookies[SESSION_COOKIE_NAME][0]

      @connection = Excon.new(url) if @connection.nil?
    end


    def cleanup #:nodoc:
      @session_id = nil
      @basic_auth = nil
      @connection = nil
    end


    private

      ###
      # Get request headers prepared with session ID and Basic Auth.
      def headers
        {'Authorization' => @basic_auth, 'Cookie' => "#{SESSION_COOKIE_NAME}=#{session_id}"}
      end

  end

end
