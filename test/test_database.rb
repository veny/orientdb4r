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
    rslt = @client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    assert_instance_of Hash, rslt
    assert rslt.size > 0
    assert rslt.include? 'classes'

    # bad DB name
    assert_raise Orientdb4r::OrientdbError do
      @client.connect :database => 'unknown_db', :user => 'admin', :password => 'admin'
    end
    # bad credentials
    assert_raise Orientdb4r::OrientdbError do
      @client.connect :database => 'temp', :user => 'admin1', :password => 'admin'
    end
  end


  ###
  # DISCONNECT
  def test_disconnect
    @client.disconnect
    assert !@client.connected?
    # unable to query after disconnect
    assert_raise Orientdb4r::OrientdbError do @client.query 'SELECT FROM OUser'; end
  end


  ###
  # CREATE DATABASE
  # Temporary disabled bacause of unknown way how to drop a new created datatabse.
  def xtest_create_database
    @client.create_database :database => 'UniT', :user => 'root', :password => 'root'
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

end
