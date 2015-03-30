module Orientdb4r

  module Binary

    class Connection

      attr_reader :session_id
      attr_reader :params

      def initialize(session_id, params)
        @session_id = session_id
        @params = params
      end

      def connected?
        !session_id.nil? and session_id < 0
      end

      def close
        @params.clear
        @params = nil
        @session_id = 0
      end

    end

  end

end