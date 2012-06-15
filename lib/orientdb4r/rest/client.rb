module Orientdb4r

  class RestClient < Client
    include Aop2

    before [:query, :command, :get_class], :assert_connected
    around [:query, :command], :time_around

    attr_reader :host, :port, :ssl, :user, :password


    def initialize(options) #:nodoc:
      super()
      options_pattern = { :host => 'localhost', :port => 2480, :ssl => false }
      verify_and_sanitize_options(options, options_pattern)
      @host = options[:host]
      @port = options[:port]
      @ssl = options[:ssl]
    end


    def connect(options) #:nodoc:
      options_pattern = { :database => :mandatory, :user => :mandatory, :password => :mandatory }
      verify_and_sanitize_options(options, options_pattern)
      @database = options[:database]
      @user = options[:user]
      @password = options[:password]

      @resource = ::RestClient::Resource.new(url, :user => user, :password => password)

      begin
        response = @resource["connect/#{@database}"].get
        rslt = process_response(response, :mode => :strict)

        decorate_classes_with_model(rslt['classes'])

        @connected = true
      rescue
        @connected = false
        raise ConnectionError
      end
      rslt
    end


    def disconnect #:nodoc:
      return unless @connected

      begin
        response = @resource['disconnect'].get
      rescue ::RestClient::Unauthorized
        Orientdb4r::logger.warn '401 Unauthorized - bug in disconnect?'
      ensure
        @connected = false
        @user = nil
        @password = nil
      end
    end


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


    def get_class(name) #:nodoc:
      raise ArgumentError, "class name is blank" if blank?(name)

      # there seems to be a bug in REST API, only data are returned
      #response = @resource["class/#{@database}/#{name}"].get
      #rslt = process_response(response)

      # workaround - use metadate delivered by 'connect'
      response = @resource["connect/#{@database}"].get
      connect_info = process_response(response, :mode => :strict)

      classes = connect_info['classes'].select { |i| i['name'] == name }
      raise ArgumentError, "class not found, name=#{name}" unless 1 == classes.size
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


    def query(sql) #:nodoc:
      raise ArgumentError, 'query is blank' if blank? sql

      response = @resource["query/#{@database}/sql/#{URI.escape(sql)}"].get
      rslt = process_response(response)
      rslt['result']
    end


    def command(sql) #:nodoc:
      raise ArgumentError, 'command is blank' if blank? sql
      begin
#puts "REQ #{sql}"
        response = @resource["command/#{@database}/sql/#{URI.escape(sql)}"].post ''
        rslt = process_response(response)
        rslt
#puts "RESP #{response.code}"
      rescue
        raise OrientdbError
      end
    end


    def server(options={}) #:nodoc:
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


    # ----------------------------------------------------------------- DOCUMENT

    def create_document(doc)
      response = @resource["document/#{@database}"].post doc.to_json, :content_type => 'application/json'
      rid = process_response(response)
      raise OrientdbError, "invalid RID format, RID=#{rid}" unless rid =~ /^#[0-9]+:[0-9]+/
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
      process_response(response)
      rslt = process_response(response)
      rslt.extend Orientdb4r::DocumentMetadata
      rslt
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
