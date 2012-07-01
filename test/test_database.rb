require 'test/unit'
require 'orientdb4r'

###
# This class tests following operations:
# * CONNECT
# * DISCONNECT
# * CREATE DATABASE
class TestDatabase < Test::Unit::TestCase

  Orientdb4r::logger.level = Logger::DEBUG

  def setup
    @client = Orientdb4r.client
  end

  ###
  # CONNECT
  def test_connect
    assert_nothing_thrown do @client.connect :database => 'temp', :user => 'admin', :password => 'admin'; end
    rslt = @client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    assert_instance_of Hash, rslt
    assert rslt.size > 0
    assert rslt.include? 'classes'

    assert_equal 'localhost', @client.host
    assert_equal 2480, @client.port
    assert_equal false, @client.ssl
    assert_equal 'admin', @client.user
    assert_equal 'admin', @client.password
    assert_equal 'temp', @client.database
    assert_not_nil @client.session_id
    assert_not_nil @client.server_version

    # connection refused
    client = Orientdb4r.client :port => 2840, :instance => :new
    assert_raise Orientdb4r::ConnectionError do
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    end

    # bad DB name
    assert_raise Orientdb4r::ConnectionError do
      @client.connect :database => 'unknown_db', :user => 'admin', :password => 'admin'
    end
    # bad credentials
    assert_raise Orientdb4r::ConnectionError do
      @client.connect :database => 'temp', :user => 'admin1', :password => 'admin'
    end
  end


  ###
  # DISCONNECT
  def test_disconnect
    @client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    assert @client.connected?
    assert_nothing_thrown do @client.disconnect; end
    assert !@client.connected?
    # unable to query after disconnect
    assert_raise Orientdb4r::ConnectionError do @client.query 'SELECT FROM OUser'; end

    assert_equal 'localhost', @client.host
    assert_equal 2480, @client.port
    assert_equal false, @client.ssl
    assert_nil @client.user
    assert_nil @client.password
    assert_nil @client.database
    assert_nil @client.session_id
    assert_nil @client.server_version
  end


  ###
  # CREATE DATABASE
  # Temporary disabled because of unknown way how to drop a new created datatabse.
  def xtest_create_database
    @client.create_database :database => 'UniT', :user => 'root', :password => 'root'
    assert_nothing_thrown do @client.get_database 'UniT'; end
    # creating an existing DB
    assert_raise Orientdb4r::OrientdbError do
      @client.create_database :database => 'UniT', :user => 'root', :password => 'root'
    end
    # insufficient rights
    assert_raise Orientdb4r::OrientdbError do
      @client.create_database :database => 'UniT1', :user => 'admin', :password => 'admin'
    end

    # By convention 3 users are always created by default every time you create a new database.
    # Default users are: admin, reader, writer
    @client.connect :database => 'UniT', :user => 'admin', :password => 'admin'
    #@client.command "DROP DATABASE UniT" : NOT WORKING now
  end


  ###
  # GET DATABASE
  def test_get_database
    @client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    assert_nothing_thrown do @client.get_database 'temp'; end

    rslt = @client.get_database 'temp'
    assert_not_nil rslt
    assert_instance_of Hash, rslt
    assert rslt.include? 'classes'
    assert @client.database_exists?('temp')

    # bad databases
    assert_raise Orientdb4r::NotFoundError do @client.get_database 'UnknownDB'; end
    assert_raise Orientdb4r::NotFoundError do @client.get_database 'temp/admin'; end
    assert !@client.database_exists?('UnknownDB')
    assert !@client.database_exists?('temp/admin')
  end


  ###
  # SERVER info
  # Temporary disabled because of dependency to password of 'root' account
  def xtest_server
    # admin/admin has not 'server.info' resource access in standard installation
    assert_raise Orientdb4r::OrientdbError do @client.server :user => 'admin', :password => 'admin'; end

    assert_nothing_thrown do @client.server :user => 'root', :password => 'root'; end
    rslt = @client.server :user => 'root', :password => 'root'
    assert_instance_of Hash, rslt
    assert rslt.include? 'connections'
    assert_not_nil rslt['connections']
  end

end
