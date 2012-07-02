module Orientdb4r

  class RestClient < Client
    include Aop2

    # Name of cookie that represents a session.
    SESSION_COOKIE_NAME = 'OSESSIONID'

    before [:query, :command], :assert_connected
    before [:create_class, :get_class, :drop_class, :create_property], :assert_connected
    before [:create_document, :get_document, :update_document, :delete_document], :assert_connected
    around [:query, :command], :time_around

    attr_reader :host, :port, :ssl, :user, :password, :database, :session_id


    def initialize(options) #:nodoc:
      super()
      options_pattern = { :host => 'localhost', :port => 2480, :ssl => false }
      verify_and_sanitize_options(options, options_pattern)
      @host = options[:host]
      @port = options[:port]
      @ssl = options[:ssl]
    end


    # --------------------------------------------------------------- CONNECTION

    def connect(options) #:nodoc:
      options_pattern = { :database => :mandatory, :user => :mandatory, :password => :mandatory }
      verify_and_sanitize_options(options, options_pattern)
      @database = options[:database]
      @user = options[:user]
      @password = options[:password]


      begin
        response = ::RestClient::Request.new(:method => :get, :url => "#{url}/connect/#{@database}", \
            :user => user, :password => password).execute
        @session_id = response.cookies[SESSION_COOKIE_NAME]
        rslt = process_response(response, :mode => :strict)

        # resource used for all request
        @resource = ::RestClient::Resource.new(url, \
            :user => user, :password => password, :cookies => { SESSION_COOKIE_NAME => session_id})

        decorate_classes_with_model(rslt['classes'])

        # try to read server version
        if rslt.include? 'server'
          @server_version = rslt['server']['version']
        else
          @server_version = DEFAULT_SERVER_VERSION
        end
        raise OrientdbError, "bad version format, version=#{server_version}" unless server_version =~ SERVER_VERSION_PATTERN
        Orientdb4r::logger.debug "successfully connected to server, version=#{server_version}, session=#{session_id}"

        @connected = true
        @session_id = response.cookies[SESSION_COOKIE_NAME]
      rescue
        @connected = false
        @session_id = nil
        @server_version = nil
        @user = nil
        @password = nil
        @database = nil
        @resource = nil
        raise ConnectionError
      end
      rslt
    end


    def disconnect #:nodoc:
      return unless @connected

      begin
        response = @resource['disconnect'].get
      rescue ::RestClient::Unauthorized
        # https://groups.google.com/forum/?fromgroups#!topic/orient-database/5MAMCvFavTc
        # Disconnect doesn't require you're authenticated.
        # It always returns 401 because some browsers intercept this and avoid to reuse the same session again.
      ensure
        @connected = false
        @server_version = nil
        @session_id = nil
        @user = nil
        @password = nil
        @database = nil
        @resource = nil
        Orientdb4r::logger.debug 'disconnected from server'
      end
    end


    def server(options={}) #:nodoc:
      # 'server' does NOT use the RestClient Resource to construct the HTTP request

      options_pattern = { :user => :optional, :password => :optional }
      verify_options(options, options_pattern)

      u = options.include?(:user) ? options[:user] : user
      p = options.include?(:password) ? options[:password] : password
      resource = ::RestClient::Resource.new(url, :user => u, :password => p)
      begin
        response = resource['server'].get
      rescue
        raise OrientdbError
      end
      process_response(response)
    end


    # ----------------------------------------------------------------- DATABASE

    def create_database(options) #:nodoc:
      options_pattern = {
        :database => :mandatory, :type => 'memory',
        :user => :optional, :password => :optional, :ssl => false
      }
      verify_and_sanitize_options(options, options_pattern)

      u = options.include?(:user) ? options[:user] : user
      p = options.include?(:password) ? options[:password] : password
      resource = ::RestClient::Resource.new(url, :user => u, :password => p)
      begin
        response = resource["database/#{options[:database]}/#{options[:type]}"].post ''
      rescue
        raise OrientdbError
      end
      process_response(response)
    end


    def get_database(name_or_options) #:nodoc:
      if name_or_options.is_a? String
        options = { :database => name_or_options }
      else
        options = name_or_options
      end
      options_pattern = { :database => :mandatory, :user => :optional, :password => :optional }
      verify_options(options, options_pattern)

      u = options.include?(:user) ? options[:user] : user
      p = options.include?(:password) ? options[:password] : password
      resource = ::RestClient::Resource.new(url, :user => u, :password => p)
      begin
        response = resource["database/#{options[:database]}"].get
      rescue
        raise NotFoundError
      end
      process_response(response)
    end


    # ---------------------------------------------------------------------- SQL

    def query(sql, options=nil) #:nodoc:
      raise ArgumentError, 'query is blank' if blank? sql

      options_pattern = { :limit => :optional }
      verify_options(options, options_pattern) unless options.nil?

      limit = ''
      limit = "/#{options[:limit]}" if !options.nil? and options.include?(:limit)
      response = @resource["query/#{@database}/sql/#{CGI::escape(sql)}#{limit}"].get
      entries = process_response(response)
      rslt = entries['result']
      # mixin all document entries (they have '@class' attribute)
      rslt.each { |doc| doc.extend Orientdb4r::DocumentMetadata unless doc['@class'].nil? }
      rslt
    end


    def command(sql) #:nodoc:
      raise ArgumentError, 'command is blank' if blank? sql
      begin
#puts "REQ command/#{@database}/sql/#{CGI::escape(sql)}"
        response = @resource["command/#{@database}/sql/#{CGI::escape(sql)}"].post ''
        rslt = process_response(response)
        rslt
#puts "RESP #{response.body}"
      rescue
        raise OrientdbError
      end
    end


    # -------------------------------------------------------------------- CLASS

    def get_class(name) #:nodoc:
      raise ArgumentError, "class name is blank" if blank?(name)

      if compare_versions(server_version, '1.1.0') >= 0
        begin
          response = @resource["class/#{@database}/#{name}"].get
        rescue
          raise NotFoundError
        end
        rslt = process_response(response, :mode => :strict)
        classes = [rslt]
      else
        # there is bug in REST API [v1.0.0, fixed in r5902], only data are returned
        # workaround - use metadate delivered by 'connect'
        response = @resource["connect/#{@database}"].get
        connect_info = process_response(response, :mode => :strict)

        classes = connect_info['classes'].select { |i| i['name'] == name }
        raise NotFoundError, "class not found, name=#{name}" unless 1 == classes.size
      end

      decorate_classes_with_model(classes)
      clazz = classes[0]
      clazz.extend Orientdb4r::HashExtension
      clazz.extend Orientdb4r::OClass
      unless clazz['properties'].nil? # there can be a class without properties
        clazz.properties.each do |prop|
          prop.extend Orientdb4r::HashExtension
          prop.extend Orientdb4r::Property
        end
      end

      clazz
    end


    # ----------------------------------------------------------------- DOCUMENT

    def create_document(doc)
      begin
        response = @resource["document/#{@database}"].post doc.to_json, :content_type => 'application/json'
      rescue
        raise DataError
      end
      rid = process_response(response)
      raise ArgumentError, "invalid RID format, RID=#{rid}" unless rid =~ /^#[0-9]+:[0-9]+/
      rid
    end


    def get_document(rid) #:nodoc:
      raise ArgumentError, 'blank RID' if blank? rid
      # remove the '#' prefix
      rid = rid[1..-1] if rid.start_with? '#'

      begin
        response = @resource["document/#{@database}/#{rid}"].get
      rescue
        raise NotFoundError
      end
      rslt = process_response(response)
      rslt.extend Orientdb4r::DocumentMetadata
      rslt
    end


    def update_document(doc) #:nodoc:
      raise ArgumentError, 'document is nil' if doc.nil?
      raise ArgumentError, 'document has no RID' if doc.doc_rid.nil?
      raise ArgumentError, 'document has no version' if doc.doc_version.nil?

      rid = doc.delete '@rid'
      rid = rid[1..-1] if rid.start_with? '#'

      begin
        @resource["document/#{@database}/#{rid}"].put doc.to_json, :content_type => 'application/json'
      rescue
        raise DataError
      end
      # empty http response
    end


    def delete_document(rid) #:nodoc:
      raise ArgumentError, 'blank RID' if blank? rid
      # remove the '#' prefix
      rid = rid[1..-1] if rid.start_with? '#'

      begin
        response = @resource["document/#{@database}/#{rid}"].delete
        puts "DELETE '#{response}'"
      rescue
        raise DataError
      end
      # empty http response
    end

    # ------------------------------------------------------------------ Helpers

    private

      ###
      # Gets URL of the REST interface.
      def url
        "http#{'s' if ssl}://#{host}:#{port}"
      end

      ###
      # ==== options
      # * strict
      # * warning
      def process_response(response, options={})
        raise ArgumentError, 'response is null' if response.nil?

        # raise problem if other code than 200
        if options[:mode] == :strict and 200 != response.code
          raise OrientdbError, "unexpeted return code, code=#{response.code}"
        end
        # log warning if other than 200 and raise problem if other code than 'Successful 2xx'
        if options[:mode] == :warning
          if 200 != response.code and 2 == (response.code / 100)
            Orientdb4r::logger.warn "expected return code 200, but received #{response.code}"
          elseif 200 != response.code
            raise OrientdbError, "unexpeted return code, code=#{response.code}"
          end
        end

        content_type = response.headers[:content_type]
        content_type ||= 'text/plain'

        rslt = case
          when content_type.start_with?('text/plain')
            response.body
          when content_type.start_with?('application/json')
            ::JSON.parse(response.body)
          end

        rslt
      end

      def decorate_classes_with_model(classes)
        classes.each do |clazz|
          clazz.extend Orientdb4r::HashExtension
          clazz.extend Orientdb4r::OClass
            unless clazz['properties'].nil? # there can be a class without properties
              clazz.properties.each do |prop|
                prop.extend Orientdb4r::HashExtension
                prop.extend Orientdb4r::Property
            end
          end
        end
      end

  end

end
