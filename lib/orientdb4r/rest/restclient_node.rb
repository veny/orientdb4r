module Orientdb4r

  ###
  # This class represents a single sever/node in the Distributed Multi-Master Architecture
  # accessible view REST API and 'rest-client' library on the client side.
  class RestClientNode < RestNode

    def oo_request(options) #:nodoc:
      begin
        response = ::RestClient::Request.new( \
            :method => options[:method], :url => "#{url}/#{options[:uri]}", \
            :user => options[:user], :password => options[:password]).execute
      rescue ::RestClient::Unauthorized
        # fake the response object
        response = "401 Unauthorized"
        def response.code
          401
        end
      end
      response
    end


    def request(options) #:nodoc:
      begin
        # e.g. @resource['disconnect'].get
        response = @resource[options[:uri]].send options[:method].to_sym
      rescue ::RestClient::Unauthorized
        # fake the response object
        response = "401 Unauthorized"
        def response.code
          401
        end
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

  end

end
