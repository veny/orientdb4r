require 'uri'

module Orientdb4r

  class Client
    include Utils

    # # Regexp to validate format of provided version.
    SERVER_VERSION_PATTERN = /^\d+\.\d+\.\d+[-SNAPHOT]*$/

    # connection parameters
    attr_reader :user, :password, :database
    # type of connection library [:restclient, :excon]
    attr_reader :connection_library
    # type of load balancing [:sequence, :round_robin]
    attr_reader :load_balancing
    # proxy for remote communication
    attr_reader :proxy

    # intern structures

    # nodes responsible for communication with a server
    attr_reader :nodes
    # object implementing a LB strategy
    attr_reader :lb_strategy

    ###
    # Constructor.
    def initialize
      @nodes = []
      @connected = false
    end


    # --------------------------------------------------------------- CONNECTION

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
    # Retrieve information about the connected OrientDB Server.
    # Enables additional authentication to the server with an account
    # that can access the 'server.info' resource.
    def server(options={})
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    # ----------------------------------------------------------------- DATABASE

    ###
    # Creates a new database.
    # You can provide an additional authentication to the server with 'database.create' resource
    # or the current one will be used.
    # *options
    #   *storage - 'memory' (by default) or 'local'
    #   *type - 'document' (by default) or 'graph'
    def create_database(options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Retrieves all the information about a database.
    # Client has not to be connected to see databases suitable to connect.
    def get_database(options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Checks existence of a given database.
    # Client has not to be connected to see databases suitable to connect.
    def database_exists?(options)
      rslt = true
      begin
        get_database options
      rescue OrientdbError
        rslt = false
      end
      rslt
    end


    ###
    # Drops a database.
    # Requires additional authentication to the server.
    def delete_database(options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Retrieves the available databases.
    # That is protected by the resource "server.listDatabases"
    # that by default is assigned to the guest (anonymous) user in orientdb-server-config.xml.
    def list_databases(options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Exports a gzip file that contains the database JSON export.
    # Returns name of stored file.
    def export(options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Imports a database from an uploaded JSON text file.
    def import(options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

    # ---------------------------------------------------------------------- SQL

    ###
    # Executes a query against the database.
    def query(sql, options)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Executes a command against the database.
    def command(sql)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    # -------------------------------------------------------------------- CLASS

    ###
    # Creates a new class in the schema.
    def create_class(name, options={})
      raise ArgumentError, "class name is blank" if blank?(name)
      opt_pattern = {
          :extends => :optional, :cluster => :optional, :force => false, :abstract => false,
          :properties => :optional
      }
      verify_options(options, opt_pattern)

      sql = "CREATE CLASS #{name}"
      sql << " EXTENDS #{options[:extends]}" if options.include? :extends
      sql << " CLUSTER #{options[:cluster]}" if options.include? :cluster
      sql << ' ABSTRACT' if options.include?(:abstract)

      drop_class name if options[:force]

      command sql

      # properties given?
      if options.include? :properties
        props = options[:properties]
        raise ArgumentError, 'properties have to be an array' unless props.is_a? Array

        props.each do |prop|
          raise ArgumentError, 'property definition has to be a hash' unless prop.is_a? Hash
          prop_name = prop.delete :property
          prop_type = prop.delete :type
          create_property(name, prop_name, prop_type, prop)
        end
      end

      if block_given?
        proxy = Orientdb4r::Utils::Proxy.new(self, name)
        def proxy.property(property, type, options={})
          self.target.send :create_property, self.context, property, type, options
        end
        def proxy.link(property, type, linked_class, options={})
          raise ArgumentError, "type has to be a linked-type, given=#{type}" unless type.to_s.start_with? 'link'
          options[:linked_class] = linked_class
          self.target.send :create_property, self.context, property, type, options
        end
        yield proxy
      end
    end


    ###
    # Gets informations about requested class.
    def get_class(name)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Checks existence of a given class.
    def class_exists?(name)
      rslt = true
      begin
        get_class name
      rescue OrientdbError => e
        raise e if e.is_a? ConnectionError and e.message == 'not connected' # workaround for AOP2 (unable to decorate already existing methods)
        rslt = false
      end
      rslt
    end


    ###
    # Removes a class from the schema.
    def drop_class(name, options={})
      raise ArgumentError, 'class name is blank' if blank?(name)

      # :mode=>:strict forbids to drop a class that is a super class for other one
      opt_pattern = { :mode => :nil }
      verify_options(options, opt_pattern)
      if :strict == options[:mode]
        response = get_database
        children = response['classes'].select { |i| i['superClass'] == name }
        unless children.empty?
          raise OrientdbError, "class is super-class, cannot be deleted, name=#{name}"
        end
      end

      command "DROP CLASS #{name}"
    end


    ###
    # Creates a new property in the schema.
    # You need to create the class before.
    def create_property(clazz, property, type, options={})
      raise ArgumentError, "class name is blank" if blank?(clazz)
      raise ArgumentError, "property name is blank" if blank?(property)
      opt_pattern = {
        :mandatory => :optional , :notnull => :optional, :min => :optional, :max => :optional,
        :readonly =>  :optional, :linked_class => :optional
      }
      verify_options(options, opt_pattern)

      cmd = "CREATE PROPERTY #{clazz}.#{property} #{type.to_s}"
      # link?
      if [:link, :linklist, :linkset, :linkmap].include? type.to_s.downcase.to_sym
        raise ArgumentError, "defined linked-type, but not linked-class" unless options.include? :linked_class
        cmd << " #{options[:linked_class]}"
      end
      command cmd

      # ALTER PROPERTY ...
      options.delete :linked_class # it's not option for ALTER
      unless options.empty?
        options.each do |k,v|
          command "ALTER PROPERTY #{clazz}.#{property} #{k.to_s.upcase} #{v}"
        end
      end
    end


    # ----------------------------------------------------------------- DOCUMENT

    ###
    # Create a new document.
    # Returns the Record-id assigned for OrientDB version <= 1.3.x
    # and the whole new document for version >= 1.4.x
    # (see https://groups.google.com/forum/?fromgroups=#!topic/orient-database/UJGAXYpHDmo for more info).
    def create_document(doc)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Retrieves a document by given ID.
    def get_document(rid)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Updates an existing document.
    def update_document(doc)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    ###
    # Deletes an existing document.
    def delete_document(rid)
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


    protected

      ###
      # Calls the server with a specific task.
      # Returns a response according to communication channel (e.g. HTTP response).
      def call_server(options)
        lb_all_bad_msg = 'all nodes failed to communicate with server!'
        response = nil

        # credentials if not defined explicitly
        options[:user] = user unless options.include? :user
        options[:password] = password unless options.include? :password
        debug_string = options[:uri]
        if debug_string
          query_log("Orientdb4r::Client#call_server", URI.decode(debug_string))
        end
        idx = lb_strategy.node_index
        raise OrientdbError, lb_all_bad_msg if idx.nil? # no good node found

        begin
          node = @nodes[idx]
          begin
            response = node.request options
            lb_strategy.good_one idx
            return response

          rescue NodeError => e
            Orientdb4r::logger.error "node error, index=#{idx}, msg=#{e.message}, #{node}"
            node.cleanup
            lb_strategy.bad_one idx
            idx = lb_strategy.node_index
          end
        end until idx.nil? and response.nil? # both 'nil' <= we tried all nodes and all with problem

        raise OrientdbError, lb_all_bad_msg
      end


      ###
      # Asserts if the client is connected and raises an error if not.
      def assert_connected
        raise ConnectionError, 'not connected' unless @connected
      end


      ###
      # Around advice to meassure and print the method time.
      def time_around(&block)
        start = Time.now
        rslt = block.call
        query_log("#{aop_context[:class].name}##{aop_context[:method]}", "elapsed time = #{Time.now - start} [s]")
        rslt
      end

      def query_log(context, message)
        Orientdb4r::logger.debug \
          "  \033[01;33m#{context}:\033[0m #{message}"
      end

  end

end
