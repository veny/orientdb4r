module Orientdb4r

  class Client

    attr_accessor :host, :port, :database, :user, :password

    def initialize
      @connected = false
      @url = "http://localhost:2480/connect/first"
    end

    class << self
      def create_class()
      end

      def drop_class()
      end
    end

    def connected?
      @connected
    end

  end

  def connect
      RestClient.get @url
  end

  ###
  # Clear any caching the database adapter may be doing, for example
  # clearing the prepared statement cache. This is database specific.
  def diconnect()
    # this should be overridden by concrete client
  end


  class RestClient << Client

    def diconnect
      RestClient.get
    end

    protected

      def url
        "#{}"
      end

  end

end
