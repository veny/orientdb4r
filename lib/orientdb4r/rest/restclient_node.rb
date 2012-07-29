require 'rest_client'

module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible via REST API and 'rest-client' library on the client side.
  class RestClientNode < RestNode

    def one_off_request(options) #:nodoc:
      opts = options.clone # if not cloned we change original hash map that cannot be used more with load balancing

      begin
        opts[:url] = "#{url}/#{opts[:uri]}"
        opts.delete :uri
        response = ::RestClient::Request.new(opts).execute
      rescue Errno::ECONNREFUSED
        raise NodeError
      rescue ::RestClient::ServerBrokeConnection
        raise NodeError
      rescue ::RestClient::Exception => e
        response = transform_error2_response(e)
      end

      response
    end


    def request(options) #:nodoc:
      raise OrientdbError, 'long life connection not initialized' if @resource.nil?

      opts = options.clone # if not cloned we change original hash map that cannot be used more with load balancing
      data = opts[:data]
      opts.delete :data
      data = '' if data.nil? and :post == opts[:method] # POST has to have data
      begin
        # e.g. @resource['disconnect'].get
        if data.nil?
          response = @resource[opts[:uri]].send opts[:method].to_sym
        else
          response = @resource[opts[:uri]].send opts[:method].to_sym, data
        end
      rescue ::RestClient::ServerBrokeConnection
        raise NodeError
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
