require 'json'
require 'rest_client'
require 'logger'
require 'orientdb4r/version'


###
# This module represents the entry point for using the Ruby OrientDB client.
module Orientdb4r

  autoload :Utils,        'orientdb4r/utils'
  autoload :Client,       'orientdb4r/client'
  autoload :RestClient,   'orientdb4r/rest/client'
  autoload :OClass,       'orientdb4r/rest/oclass'


  class << self

    ###
    # Gets a new database client or an existing for the current thread.
    def client options={}
      Thread.current[:orientdb_client] ||= RestClient.new options
    end

    ###
    # All calls to REST API will use the proxy specified here.
    def rest_proxy(url)
      RestClient.proxy = url
    end

    attr_accessor :logger

  end


  ###
  # Basic error raised to signal an unexpected situation.
  class OrientdbError < StandardError; end

end


# Configuration of logging.
Orientdb4r::logger = Logger.new(STDOUT)
Orientdb4r::logger.level = Logger::INFO

Orientdb4r::logger.info \
  "Orientdb4r #{Orientdb4r::VERSION}, running on Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
