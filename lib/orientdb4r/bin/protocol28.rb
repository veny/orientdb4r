require 'bindata'

module Orientdb4r

  module Binary

    class Protocol28

      # Common Constructs -----------------------------------------------------

      class ProtocolString < BinData::Primitive
        endian :big

        int32  :len,  :value => lambda { data.length }
        string :data, :read_length => :len, :onlyif => :not_blank?

        def get;   self.data; end
        def set(v) self.data = v; end

        def not_blank?
          len > 0
        end
      end


      class Errors < BinData::Record
        endian :big

        int32 :session
        array :exceptions, read_until: -> { element[:is_error] < 1 } do
          int8 :is_error
          protocol_string :exception_class, onlyif: -> { 1 == is_error }
          protocol_string :exception_message, onlyif: -> { 1 == is_error }
        end

        int32 :len
        skip  :length => :len
      end

      # -----------------------------------------------------------------------

      class DbOpenRequest < BinData::Record
        endian :big

        int8            :operation,       :value => ::Orientdb4r::Binary::Constants::REQUEST_DB_OPEN
        int32           :session,         :value => -123456

        protocol_string :driver_name,     :value => Orientdb4r::DRIVER_NAME
        protocol_string :driver_version,  :value => Orientdb4r::VERSION
        int16           :protocol_version
        protocol_string :client_id
        protocol_string :serialization_impl, :value => 'ORecordDocument2csv'
        int8            :token_based,     :value => 0
        protocol_string :db_name
        protocol_string :db_type,         :value => 'document'
        protocol_string :user
        protocol_string :password
      end

      class DbOpenResponse < BinData::Record
        endian :big

        int32 :session
        skip :length => 8
        int16 :num_of_clusters
        array :clusters, :initial_length => :num_of_clusters do
          protocol_string :name
          int16 :cluster_id
        end
        #int8 :cluster_config_bytes
        protocol_string :cluster_config_bytes
        #skip :length => 4
        #protocol_string :neco
        protocol_string :orientdb_release
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

class ConnectAnswer < BinData::Record
      endian :big

      skip length: 4
      int32 :session
    end

    end

  end

end
