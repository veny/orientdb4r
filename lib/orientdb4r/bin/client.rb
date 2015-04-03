require 'socket'
require 'bindata'
require 'orientdb4r/bin/constants'
require 'orientdb4r/bin/protocol_factory'
require 'orientdb4r/bin/io'
require 'orientdb4r/bin/connection'

module Orientdb4r

  module Binary

    ###
    # This client implements the binary protocol.
    class BinClient < Client
      include Binary::Constants
      include Binary::OIO

      attr_reader :server_connection
      attr_reader :db_connection
      attr_reader :protocol
      attr_reader :protocol_version


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
        options_pattern = { :database => :mandatory, :user => :mandatory, :password => :mandatory, :session => :optional, :db_type => 'document' }
        verify_and_sanitize_options(options, options_pattern)

        @socket = TCPSocket.open(@host, @port)
        @protocol_version = BinData::Int16be.read(@socket).to_i

        Orientdb4r::logger.info "Binary protocol version: #{@protocol_version}"

        # check minimal protocol version which is supported
        @protocol = ProtocolFactory.get_protocol(protocol_version)

        command = protocol::DbOpenRequest.new(:protocol_version => protocol_version, :db_name => options[:database], :user => options[:user], :password => options[:password])

        resp = req_resp(@socket, command, protocol::DbOpenResponse.new)
        db_connection = Orientdb4r::Binary::Connection.new(resp.session, options)
        Orientdb4r::logger.info "Database connected, session=#{db_connection.session_id}"
      end


      def disconnect #:nodoc:
        @socket.close
        @protocol = nil
        @protocol_version = 0
        @db_connection.close unless @db_connection.nil?
        @server_connection.close unless @server_connection.nil?
        @db_connection = nil
      end


      def server(options={})
        raise NotImplementedError, 'this should be overridden by concrete client'
      end


      # ------------------------------------------------------------------ Helpers

      private

        # Gets a hash of parameters.
        def params(args = {})
          args.merge({ session: connection.session })
        end

    end

  end

end
