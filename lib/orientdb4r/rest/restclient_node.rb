require 'rest_client'

module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible view REST API and 'rest-client' library on the client side.
  class RestClientNode < RestNode


    def oo_request(options) #:nodoc:
      begin
        options[:url] = "#{url}/#{options[:uri]}"
        options.delete :uri
        response = ::RestClient::Request.new(options).execute
      rescue ::RestClient::Exception => e
        response = transform_error2_response(e)
      end

      response
    end


    def request(options) #:nodoc:
      raise OrientdbError, 'long life connection not initialized' if @resource.nil?

      data = options[:data]
      options.delete :data
      data = '' if data.nil? and :post == options[:method] # POST has to have data
      begin
        # e.g. @resource['disconnect'].get
        if data.nil?
          response = @resource[options[:uri]].send options[:method].to_sym
        else
          response = @resource[options[:uri]].send options[:method].to_sym, data
        end
      rescue ::RestClient::Exception => e
        response = transform_error2_response(e)
      end

      response
    end


    def post_connect(user, password, http_response) #:nodoc:
      @basic_auth = basic_auth_header(user, password)
      @session_id = http_response.cookies[SESSION_COOKIE_NAME]

      @resource = ::RestClient::Resource.new(url, \
            :user => user, :password => password, \
            :cookies => { SESSION_COOKIE_NAME => session_id})
    end


    def cleanup #:nodoc:
      @session_id = nil
      @basic_auth = nil
      @resource = nil
    end


    private

      ###
      # Fakes an error thrown by the library into a response object with methods
      # 'code' and 'body'.
      def transform_error2_response(error)
        response = ["#{error.message}: #{error.http_body}", error.http_code]
        def response.body
          self[0]
        end
        def response.code
          self[1]
        end
        response
      end

  end

end
