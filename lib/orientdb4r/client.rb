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
    def command(sql, options={})
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

      raise ArgumentError, "class name is blank" if blank?(name)
      opt_pattern = { :extends => :optional , :cluster => :optional, :force => false }
      verify_options(options, opt_pattern)

      sql = "CREATE CLASS #{name}"
      sql << " EXTENDS #{options[:extends]}" if options.include? :extends
      sql << " CLUSTER #{options[:cluster]}" if options.include? :cluster

      command sql, :http_code_500 => 'failed to create class (exists already?)'
    end

    ###
    # Removes a class from the schema.
    def drop_class(name)
      raise ArgumentError, "class name is blank" if blank?(name)
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

end
