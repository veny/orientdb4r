module Orientdb4r

  class Client
    include Utils

    ###
    # Constructor.
    def initialize
      @connected = false
    end

    ###
    # Connects client to the server.
    def connect options
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    ###
    # Disconnects client from the server.
    def disconnect
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    ###
    # Gets flag whenever the client is connected or not.
    def connected?
      @connected
    end

    ###
    # Creates a new database.
    # You can provide an additional authentication to the server with 'database.create' resource
    # or the current one will be used.
    def create_database options
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    ###
    # Executes a query against the database.
    def query(sql)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    ###
    # Executes a command against the database.
    def command(sql)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    ###
    # Creates a new class in the schema.
    def create_class(name, options={})
#create_table :field, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8', :force => false do |t|
#  t.column :entity, :integer, :null => false
#  t.column :name, :integer, :null => false
#  t.column :type, :integer, :null => false
#  t.column :mandatory, :boolean, :null => false, :default => 0
#  t.column :search, :boolean, :null => false, :default => 0
#  t.column :whoset, :string
#  t.column :stamp, :integer
#end

      raise "name is blank" if name.nil? or name.strip.empty?
      opt_pattern = { :extends => :optional , :cluster => :optional }
      verify_options(options, opt_pattern)

      sql = "CREATE CLASS #{name}"
      sql << " EXTENDS #{options[:extends]}" if options.include? :extends
      sql << " CLUSTER #{options[:cluster]}" if options.include? :cluster

      command sql
    end

    ###
    # Removes a class from the schema.
    def drop_class(name)
      raise "name is blank" if name.nil? or name.strip.empty?
      command "DROP CLASS #{name}"
    end

    protected

      ###
      # Asserts if the client is connected and raises an error if not.
      def assert_connected
        raise OrientdbError, "not connected" unless @connected
      end

      def time_around(&block)
        start = Time.now
        rslt = block.call
        puts "#{aop_context[:class].name}##{aop_context[:method]}: elapsed time = #{Time.now - start} [s]"
        rslt
      end

  end



  class RestClient < Client
    include Aop2

    before [:disconnect, :query, :command], :assert_connected
    around [:query, :command], :time_around

    attr_reader :host, :port, :ssl, :user, :password


    def initialize options #:nodoc:
      super()
      options_pattern = { :host => 'localhost', :port => 2480, :ssl => false }
      verify_and_sanitize_options(options, options_pattern)
      @host = options[:host]
      @port = options[:port]
      @ssl = options[:ssl]
    end


    def connect options #:nodoc:
      options_pattern = { :database => :mandatory, :user => :mandatory, :password => :mandatory }
      verify_and_sanitize_options(options, options_pattern)
      @database = options[:database]
      @user = options[:user]
      @password = options[:password]

      @resource = ::RestClient::Resource.new(url, :user => user, :password => password)

      begin
        response = @resource["connect/#{@database}"].get
        rslt = process_response(response, :mode => :strict)
        @connected = true
      rescue ::RestClient::Exception => e
        @connected = false
        raise process_error e, :http_code_401 => 'connect failed (bad credentials?)'
      rescue Exception => e
        # TODO use logging
        $stderr.puts e.message
        $stderr.puts e.backtrace.inspect
        @connected = false
        raise e
      end
      rslt
    end


    def disconnect #:nodoc:
      begin
        @resource['disconnect'].get
      rescue ::RestClient::Unauthorized
        # TODO use logging library
        puts "warning: 401 Unauthorized - bug in disconnect?"
      ensure
        @connected = false
      end
    end


    ###
    # :name
    def create_database options={} #:nodoc:
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
      rescue ::RestClient::Exception => e
        raise process_error e, \
          :http_code_403 => 'forbidden operation (insufficient rights?)', \
          :http_code_500 => 'failed to create database (exists already?)'

      end
      process_response(response)
    end


    def query(sql) #:nodoc:
      response = @resource["query/#{@database}/sql/#{URI.escape(sql)}"].get
      rslt = process_response(response)
      rslt['result']
    end

    def command(sql) #:nodoc:
      begin
      rslt = @resource["command/#{@database}/sql/#{URI.escape(sql)}"].post ''
      rslt.to_i
      rescue Exception => e
        raise process_error e
      end
    end

    private

      ###
      # Gets URL for the REST interface.
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
            # TODO use logging library
            puts "warning: return code: expected 200, but receved #{return code}"
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

      def process_error(error, messages={})
        code = "http_code_#{error.http_code}".to_sym
        msg = messages.include?(code) ? "#{messages[code]}, cause = " : ''
        OrientdbError.new "#{msg}#{error.to_s}"
      end

  end

end
