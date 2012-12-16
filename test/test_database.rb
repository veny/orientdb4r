require 'test/unit'
require 'orientdb4r'

###
# This class tests following operations:
# * CONNECT
# * DISCONNECT
# * CREATE DATABASE
# * GET DATABASE
# * DELETE DATABASE
# * SERVER info
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

    assert_equal 'admin', @client.user
    assert_equal 'admin', @client.password
    assert_equal 'temp', @client.database
    assert_not_nil @client.server_version

    # connection refused
    client = Orientdb4r.client :port => 2840, :instance => :new
    assert_raise Orientdb4r::ConnectionError do
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    end

    # bad DB name
    assert_raise Orientdb4r::UnauthorizedError do
      @client.connect :database => 'unknown_db', :user => 'admin', :password => 'admin'
    end
    # bad DB name with '/' => wrong REST resource
    assert_raise Orientdb4r::ServerError do
      @client.connect :database => 'temp/temp', :user => 'admin', :password => 'admin'
    end
    # bad credentials
    assert_raise Orientdb4r::UnauthorizedError do
      @client.connect :database => 'temp', :user => 'admin1', :password => 'admin'
    end

    # clean up
    @client.disconnect
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

    assert_nil @client.user
    assert_nil @client.password
    assert_nil @client.database
    assert_nil @client.server_version
  end


  ###
  # CREATE DATABASE
  # Temporary disabled because of dependency to password of 'root' account
  def xtest_create_database
    assert_nothing_thrown do
      @client.create_database :database => 'UniT', :user => 'root', :password => 'root'
    end
    assert_nothing_thrown do
      @client.get_database :database => 'UniT', :user => 'admin', :password => 'admin'
    end
    # creating an existing DB
    assert_raise Orientdb4r::ServerError do
      @client.create_database :database => 'UniT', :user => 'root', :password => 'root'
    end
    # insufficient rights
    assert_raise Orientdb4r::OrientdbError do
      @client.create_database :database => 'UniT1', :user => 'admin', :password => 'admin'
    end

    # By convention 3 users are always created by default every time you create a new database.
    # Default users are: admin, reader, writer
    assert_nothing_thrown do
      @client.connect :database => 'UniT', :user => 'admin', :password => 'admin'
    end
    @client.delete_database({:database => 'UniT', :user => 'root', :password => 'root'})
  end


  ###
  # GET DATABASE
  def test_get_database
    # not connected - allowed with additional authentication
    assert_nothing_thrown do @client.get_database :database => 'temp', :user => 'admin', :password => 'admin' ; end
    assert_raise Orientdb4r::ConnectionError do @client.get_database; end
    # connected
    @client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    assert_nothing_thrown do @client.get_database; end # gets info about connected DB

    rslt = @client.get_database
    assert_not_nil rslt
    assert_instance_of Hash, rslt
    assert rslt.include? 'classes'

    # bad databases
    assert_raise Orientdb4r::UnauthorizedError do @client.get_database :database => 'UnknownDB'; end
    assert_raise Orientdb4r::ServerError do @client.get_database :database => 'temp/admin'; end # bad REST resource


    # database_exists?
    assert @client.database_exists?(:database => 'temp', :user => 'admin', :password => 'admin')
    assert @client.database_exists?(:database => 'temp') # use credentials of logged in user
    assert !@client.database_exists?(:database => 'UnknownDB')
    assert !@client.database_exists?(:database => 'temp/admin')
  end


  ###
  # DELETE DATABASE
  # Temporary disabled because of dependency to password of 'root' account
  def xtest_delete_database
    @client.create_database :database => 'UniT', :user => 'root', :password => 'root'

    # deleting non-existing DB
    assert_raise Orientdb4r::ServerError do
      @client.delete_database :database => 'UniT1', :user => 'root', :password => 'root'
    end
    # insufficient rights
    assert_raise Orientdb4r::OrientdbError do
      @client.delete_database :database => 'UniT', :user => 'admin', :password => 'admin'
    end

    assert_nothing_thrown do
      @client.delete_database({:database => 'UniT', :user => 'root', :password => 'root'})
    end
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


  ###
  # GET List Databases
  # Retrieves the available databases.
  def test_list_databases
    dbs = @client.list_databases
    assert_not_nil dbs
    assert_instance_of Array, dbs
    assert !dbs.empty?
    assert dbs.include? 'temp'
  end


  ###
  # Test of :assert_connected before advice.
  def test_assert_connected
    assert_raise Orientdb4r::ConnectionError do @client.query 'SELECT FROM OUser'; end
    assert_raise Orientdb4r::ConnectionError do @client.query "INSERT INTO OUser(name) VALUES('x')"; end
    #BF #21 assert_raise Orientdb4r::ConnectionError do @client.create_class 'x'; end
    assert_raise Orientdb4r::ConnectionError do @client.create_property 'x', 'prop', :boolean; end
    assert_raise Orientdb4r::ConnectionError do @client.get_class 'x'; end
    assert_raise Orientdb4r::ConnectionError do @client.drop_class 'x'; end
    assert_raise Orientdb4r::ConnectionError do @client.create_document({ '@class' => 'x', :prop => 1 }); end
    assert_raise Orientdb4r::ConnectionError do @client.get_document('#1:0'); end
    assert_raise Orientdb4r::ConnectionError do @client.update_document({}); end
    assert_raise Orientdb4r::ConnectionError do @client.delete_document('#1:0'); end
  end


  ###
  # Tests using of session ID.
  def test_session_id
    client = Orientdb4r.client :instance => :new
    assert_nil client.nodes[0].session_id
    client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    session_id = client.nodes[0].session_id
    assert_not_nil session_id
    client.query 'SELECT count(*) FROM OUser'
    assert_equal session_id, client.nodes[0].session_id
    client.get_class 'OUser'
    assert_equal session_id, client.nodes[0].session_id
    client.disconnect
    assert_nil client.nodes[0].session_id
  end

end
