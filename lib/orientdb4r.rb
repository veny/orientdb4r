require 'json'
require 'base64'
require 'logger'
require 'orientdb4r/version'


###
# This module represents the entry point for using the Ruby OrientDB client.
module Orientdb4r

  autoload :Utils,          'orientdb4r/utils'
  autoload :Client,         'orientdb4r/client'
  autoload :RestClient,     'orientdb4r/rest/client'
  autoload :HashExtension,  'orientdb4r/rest/model'
  autoload :OClass,         'orientdb4r/rest/model'
  autoload :ChainedError,   'orientdb4r/chained_error'
  autoload :Node,           'orientdb4r/node'
  autoload :RestNode,       'orientdb4r/rest/node'
  autoload :RestClientNode, 'orientdb4r/rest/restclient_node'


  class << self

    ###
    # Gets a new database client or an existing for the current thread.
    # === options
    #  * :instance => :new
    def client options={}
      if :new == options[:instance]
        options.delete :instance
        return RestClient.new options
      end

      Thread.exclusive {
        Thread.current[:orientdb_client] ||= RestClient.new options
      }
    end

    ###
    # All calls to REST API will use the proxy specified here.
    def rest_proxy(url)
      RestClient.proxy = url
    end

    attr_accessor :logger

  end


  ###
  # Basic error that indicates an unexpected situation during the client call.
  class OrientdbError < StandardError
    include ChainedError
  end

  ###
  # Error indicating that access to the resource requires user authentication.
  class UnauthorizedError < OrientdbError; end

  ###
  # Error indicating problems with communicating with the database.
  class ConnectionError < OrientdbError; end

  ###
  # Error raised to inform that an object identified by RID cannot be get.
  class NotFoundError < OrientdbError; end

  ###
  # Error indicating that manipulation against the given data resulted in some illegal operation,
  # mismatched types or incorrect cardinality.
  class DataError < OrientdbError; end

end


# Configuration of logging.
Orientdb4r::logger = Logger.new(STDOUT)
Orientdb4r::logger.level = Logger::INFO

Orientdb4r::logger.info \
  "Orientdb4r #{Orientdb4r::VERSION}, running on Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"


#Orientdb4r::logger.level = Logger::DEBUG
#client = Orientdb4r.client
#client.connect :database => 'temp', :user => 'admin', :password => 'admin'
