require 'json'
require 'rest_client'
require 'logger'


###
# This module represents the entry point for using the Ruby OrientDB client.
module Orientdb4r

  autoload :Utils,        'orientdb4r/utils'
  autoload :Client,       'orientdb4r/client'
  autoload :RestClient,   'orientdb4r/rest/client'


  # Version history.
  VERSION_HISTORY = [
    ['0.1.1', '2012-06-08 08:21:02 +0200', 'First working version (including unit tests)'],
    ['0.1.0', '2012-06-02 21:02:30 +0200', 'Initial version on Ruby-1.9.3p194 and OrientDB-1.0.0']
  ]

  # Current version.
  VERSION = VERSION_HISTORY[0][0]


  # Configuration of logging.
  DEFAULT_LOGGER = Logger.new(STDOUT)
  DEFAULT_LOGGER.level = Logger::DEBUG


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

  end


  ###
  # Basic error raised to signal an unexpected situation.
  class OrientdbError < StandardError; end

end


Orientdb4r::DEFAULT_LOGGER.info \
  "Orientdb4r #{Orientdb4r::VERSION}, running on Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
