require 'json'
require 'rest_client'
require 'orientdb4r/utils'
require 'orientdb4r/client'

module Orientdb4r

  class << self

    ###
    # Gets a new database client or an existing for the current thread.
    def client(options)
      Thread.current[:orientdb_client] ||= RestClient.new options
    end

    ###
    # All calls to REST API will use the proxy specified here.
    def rest_proxy(url)
      RestClient.proxy = url
    end

  end

  ###
  # Basic error raised to signal an unexpected situation.
  class OrientdbError < StandardError
  end

end
