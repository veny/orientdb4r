require 'rest_client'

module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible via REST API and 'rest-client' library on the client side.
  class RestClientNode < RestNode

    def request(options) #:nodoc:
      verify_options(options, {:user => :mandatory, :password => :mandatory, \
          :uri => :mandatory, :method => :mandatory, :content_type => :optional, :data => :optional})

      opts = options.clone # if not cloned we change original hash map that cannot be used more with load balancing

      # URL
      opts[:url] = "#{url}/#{opts[:uri]}"
      opts.delete :uri

      # data
      data = opts.delete :data
      data = '' if data.nil? and :post == opts[:method] # POST has to have data
      opts[:payload] = data unless data.nil?

      # headers
      opts[:cookies] = { SESSION_COOKIE_NAME => session_id} unless session_id.nil?

      begin
        response = ::RestClient::Request.new(opts).execute

        # store session ID if received to reuse in next request
        sessid = response.cookies[SESSION_COOKIE_NAME]
        if session_id != sessid
          @session_id = sessid
          Orientdb4r::logger.debug "new session id: #{session_id}"
        end

      rescue Errno::ECONNREFUSED
        raise NodeError
      rescue ::RestClient::ServerBrokeConnection
        raise NodeError
      rescue ::RestClient::Exception => e
        response = transform_error2_response(e)
      end

      response
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
