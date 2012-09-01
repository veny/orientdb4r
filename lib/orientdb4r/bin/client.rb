require 'socket'
require 'bindata'

module Orientdb4r

  ###
  # This client implements the binary protocol.
  class BinClient < Client


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
      protocol = BinData::Int16be.read(socket)

      Orientdb4r::logger.info "Binary protocol number: #{protocol}"

      command = DbOpen.new
      command.version = protocol
      command.database = 'temp'
      command.user = 'admin'
      command.password = 'admin'
      command.write(socket)

      resp = BinData::Int8.read(socket).to_i
      puts "EE #{resp}"

      socket.close
    end


    def disconnect #:nodoc:
    end


    def server(options={})
      raise NotImplementedError, 'this should be overridden by concrete client'
    end

class ProtocolString < BinData::Primitive
        endian    :big

        int32   :len,   :value => lambda { data.length }
        string  :data,  :read_length => :len

        def get;   self.data; end
        def set(v) self.data = v; end
      end
class DbOpen < BinData::Record
          endian :big

          int8            :operation,       :value => 3  #DB_OPEN
          int32           :session,         :value => -1 #NEW_SESSION

          protocol_string :driver,          :value => 'Orientdb4r Ruby Client'
          protocol_string :driver_version,  :value => Orientdb4r::VERSION
          int16           :version
          protocol_string :client_id
          protocol_string :database
          protocol_string :user
          protocol_string :password
        end
class Connect < BinData::Record
          endian :big

          int8            :operation,       :value => 2
          int32           :session,         :value => -1 #NEW_SESSION
          protocol_string :driver,          :value => 'Orientdb4r Ruby Client'
          protocol_string :driver_version,  :value => Orientdb4r::VERSION
          int16           :version
          protocol_string :client_id
          protocol_string :user
          protocol_string :password
        end

  end

end
