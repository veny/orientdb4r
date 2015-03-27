require 'socket'
require 'bindata'
require 'orientdb4r/bin/constants'
require 'orientdb4r/bin/protocol_factory'

module Orientdb4r

  ###
  # This client implements the binary protocol.
  class BinClient < Client
    include BinConstants

    def initialize(options) #:nodoc:
      super()
      options_pattern = {
        :host => 'localhost', :port => 2424
      }
      verify_and_sanitize_options(options, options_pattern)

      @host = options[:host]
      @port = options[:port]
    end


    # --------------------------------------------------------------- CONNECTION

    def connect options #:nodoc:
      options_pattern = { :database => :mandatory, :user => :mandatory, :password => :mandatory }
      verify_and_sanitize_options(options, options_pattern)
      @database = options[:database]
      @user = options[:user]
      @password = options[:password]

      socket = TCPSocket.open(@host, @port)
      protocol_version = BinData::Int16be.read(socket).to_i

      Orientdb4r::logger.info "Binary protocol version: #{protocol_version}"

      # check minimal protocol version which is supported
      #raise ConnectionError, "Protocols >= #{MINIMAL_PROTOCOL_VERSION} are supported. Please upgrade your OrientDb server." if protocol_version < MINIMAL_PROTOCOL_VERSION
      protocol = ProtocolFactory.get_protocol(protocol_version)

      command = protocol::DbOpen.new
      command.protocol_version = protocol_version
      command.db_name = @database
      command.user = @user
      command.password = @password
      command.write(socket)

      read_response(socket)

      resp = { :session => read_integer(socket) }

      # status = BinData::Int8.read(socket)
      # session = BinData::Int32be.read(socket).to_i
puts "EE resp = #{resp.inspect}"

      socket.close
    end


    def disconnect #:nodoc:
    end


    def server(options={})
      raise NotImplementedError, 'this should be overridden by concrete client'
    end


      # class Connect < BinData::Record
      #     endian :big

      #     int8            :operation,       :value => 2
      #     int32           :session,         :value => -1
      #     protocol_string :driver,          :value => 'Orientdb4r Ruby Client'
      #     protocol_string :driver_version,  :value => Orientdb4r::VERSION
      #     int16           :version
      #     protocol_string :client_id
      #     protocol_string :user
      #     protocol_string :password
      # end
      # class DbOpen < BinData::Record
      #     endian :big

      #     int8            :operation,       :value => 3 #Orientdb4r::BinConstants::REQUEST_DB_OPEN
      #     int32           :session,         :value => -1

      #     protocol_string :driver_name,     :value => Orientdb4r::DRIVER_NAME
      #     protocol_string :driver_version,  :value => Orientdb4r::VERSION
      #     int16           :protocol_version
      #     protocol_string :client_id
      #     protocol_string :serialization_impl, :value => 'ORecordDocument2csv'
      #     int8            :token_based,     :value => 0
      #     protocol_string :db_name
      #     protocol_string :db_type,         :value => 'document'
      #     protocol_string :user
      #     protocol_string :password
      # end
    # ------------------------------------------------------------------ Helpers

    private

      # Gets a hash of parameters.
      def params(args = {})
        args.merge({ session: connection.session })
      end

      def read_response(socket)
        result = BinData::Int8.read(socket).to_i
        raise_response_error(socket) unless result == Status::OK
      end
      def raise_response_error(socket)
        session = read_integer(socket)
        exceptions = []

        while (result = read_byte(socket)) == Status::ERROR
          exceptions << {
            :exception_class => read_string(socket),
            :exception_message => read_string(socket)
          }
        end

        Orientdb4r::logger.error "exception(s): #{exceptions}"

        # if exceptions[0] && exceptions[0][:exception_class] == "com.orientechnologies.orient.core.exception.ORecordNotFoundException"
        #   raise RecordNotFound.new(session)
        # else
        #  raise ServerError.new(session, *exceptions)
        # end
      end
      def read_integer(socket)
        BinData::Int32be.read(socket).to_i
      end
      def read_byte(socket)
        BinData::Int8.read(socket).to_i
      end

  end

end
