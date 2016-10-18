require 'test_helper'

###
# This class tests DB management.
class TestDatabase < Test::Unit::TestCase

  DB = 'temp'

  def setup
    @client = Orientdb4r.client
  end

  def teardown
    if @client.database_exists? :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS
      @client.delete_database :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS
    end
    @client.disconnect
  end

  ###
  # CONNECT
  def test_connect
    assert_nothing_thrown do @client.connect :database => DB, :user => 'admin', :password => 'admin'; end
    rslt = @client.connect :database => DB, :user => 'admin', :password => 'admin'
    assert_instance_of TrueClass, rslt

    assert_equal 'admin', @client.user
    assert_equal 'admin', @client.password
    assert_equal DB, @client.database

    # connection refused
    client = Orientdb4r.client :port => 2840, :instance => :new
    assert_raise Orientdb4r::ConnectionError do
      client.connect :database => DB, :user => 'admin', :password => 'admin'
    end

    # bad DB name
    assert_raise Orientdb4r::UnauthorizedError do
      @client.connect :database => 'unknown_db', :user => 'admin', :password => 'admin'
    end
    # !!! curl -v --user admin:adminX http://localhost:2480/connect/foo/bar
#    # bad DB name with '/' => wrong REST resource
#    assert_raise Orientdb4r::ServerError do
#      @client.connect :database => 'temp/temp', :user => 'admin', :password => 'admin'
#    end
    # bad credentials
    assert_raise Orientdb4r::UnauthorizedError do
      @client.connect :database => DB, :user => 'admin1', :password => 'admin'
    end
  end


  ###
  # DISCONNECT
  def test_disconnect
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
    assert @client.connected?
    assert_nothing_thrown do @client.disconnect; end
    assert !@client.connected?
    # unable to query after disconnect
    assert_raise Orientdb4r::ConnectionError do @client.query 'SELECT FROM OUser'; end

    assert_nil @client.user
    assert_nil @client.password
    assert_nil @client.database
  end


  ###
  # CREATE DATABASE
  def test_create_database
    # bad options
    assert_raise ArgumentError do @client.create_database(:database => 'UniT', :storage => :foo); end
    assert_raise ArgumentError do @client.create_database(:database => 'UniT', :type => :foo); end

    assert_nothing_thrown do
      @client.create_database :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS
    end
    assert_nothing_thrown do
      @client.get_database :database => 'UniT', :user => 'admin', :password => 'admin'
    end
    # creating an existing DB
    assert_raise Orientdb4r::StateConflictError do
      @client.create_database :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS
    end
    # insufficient rights
    assert_raise Orientdb4r::UnauthorizedError do
      @client.create_database :database => 'UniT1', :user => 'admin', :password => 'admin'
    end

    # By convention 3 users are always created by default every time you create a new database.
    # Default users are: admin, reader, writer
    assert_nothing_thrown do
      @client.connect :database => 'UniT', :user => 'admin', :password => 'admin'
    end
    @client.delete_database({:database => 'UniT', :user => 'root', :password => DB_ROOT_PASS})

    # create non-default DB: storage=local;type=graph
    assert_nothing_thrown do
      @client.create_database :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS, :storage => :plocal, :type => :graph
      @client.delete_database :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS
    end
  end


  ###
  # GET DATABASE
  def test_get_database
    # not connected - allowed with additional authentication
    assert_nothing_thrown do @client.get_database :database => DB, :user => 'admin', :password => 'admin' ; end
    assert_raise Orientdb4r::ConnectionError do @client.get_database; end
    # connected
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
    assert_nothing_thrown do @client.get_database; end # gets info about connected DB

    rslt = @client.get_database
    assert_not_nil rslt
    assert_instance_of Hash, rslt
    assert !rslt.empty?
    # server
    assert rslt.include? 'server'
    assert_instance_of Hash, rslt['server']
    assert !rslt['server'].empty?
    assert rslt['server'].include? 'version'
    # classes
    assert rslt.include? 'classes'
    assert_instance_of Array, rslt['classes']
    assert !rslt['classes'].empty?

    # bad databases
    assert_raise Orientdb4r::UnauthorizedError do @client.get_database :database => 'UnknownDB'; end
    assert_raise Orientdb4r::ServerError do @client.get_database :database => 'temp/admin'; end # bad REST resource


    # database_exists?
    assert @client.database_exists?(:database => DB, :user => 'admin', :password => 'admin')
    assert @client.database_exists?(:database => DB) # use credentials of logged in user
    assert !@client.database_exists?(:database => 'UnknownDB')
    assert !@client.database_exists?(:database => 'temp/admin')
  end


  ###
  # DELETE DATABASE
  def test_delete_database
    @client.create_database :database => 'UniT', :user => 'root', :password => DB_ROOT_PASS

    # deleting non-existing DB
    assert_raise Orientdb4r::ServerError do
      @client.delete_database :database => 'UniT1', :user => 'root', :password => DB_ROOT_PASS
    end
    # insufficient rights
    assert_raise Orientdb4r::UnauthorizedError do
      @client.delete_database :database => 'UniT', :user => 'admin', :password => 'admin'
    end

    assert_nothing_thrown do
      @client.delete_database({:database => 'UniT', :user => 'root', :password => DB_ROOT_PASS})
    end
  end


  ###
  # SERVER info
  def xtest_server
    # admin/admin has not 'server.info' resource access in standard installation
    assert_raise Orientdb4r::OrientdbError do @client.server :user => 'admin', :password => 'admin'; end

    assert_nothing_thrown do @client.server :user => 'root', :password => DB_ROOT_PASS; end
    rslt = @client.server :user => 'root', :password => DB_ROOT_PASS
    assert_instance_of Hash, rslt
    assert rslt.include? 'connections'
    assert_not_nil rslt['connections']
  end


  ###
  # GET List Databases
  # Retrieves the available databases.
  def test_list_databases
    dbs = @client.list_databases :user => 'root', :password => DB_ROOT_PASS
    assert_not_nil dbs
    assert_instance_of Array, dbs
    assert !dbs.empty?
    assert dbs.include? DB
  end


  ###
  # Test of :assert_connected before advice.
  def test_assert_connected
    @client.disconnect if @client.connected? # to be sure it this method is called as first in this TestCase and thread local client is still connected
    assert_raise Orientdb4r::ConnectionError do @client.query 'SELECT FROM OUser'; end
    assert_raise Orientdb4r::ConnectionError do @client.command "INSERT INTO OUser(name) VALUES('x')"; end
    assert_raise Orientdb4r::ConnectionError do @client.gremlin("g.addVertex('class:X', 'prop1', 1, 'prop2', 'string1')"); end
    assert_raise Orientdb4r::ConnectionError do @client.batch({:transaction => true, :operations => []}); end
    #BF #21 assert_raise Orientdb4r::ConnectionError do @client.create_class 'x'; end
    assert_raise Orientdb4r::ConnectionError do @client.create_property 'x', 'prop', :boolean; end
    assert_raise Orientdb4r::ConnectionError do @client.class_exists? 'x'; end
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
    client.connect :database => DB, :user => 'admin', :password => 'admin'
    session_id = client.nodes[0].session_id
    assert_not_nil session_id
    client.query 'SELECT count(*) FROM OUser'
    assert_equal session_id, client.nodes[0].session_id
    client.get_class 'OUser'
    assert_equal session_id, client.nodes[0].session_id
    client.disconnect
    assert_nil client.nodes[0].session_id
  end


  ###
  # EXPORT
  def test_export
    client = Orientdb4r.client :instance => :new

    # export of connected database
    client.connect :database => DB, :user => 'admin', :password => 'admin'
    rslt = client.export
    assert File.exist? './temp.gz'
    assert File.file? './temp.gz'
    assert 'temp.gz', rslt
    File.delete './temp.gz'

    # export with given file
    given_filename = "#{Dir.tmpdir}/TEMP.gz"
    client.export :file => given_filename
    assert File.exist? given_filename
    assert File.file? given_filename
    assert given_filename, rslt

    # explicit given DB
    client.disconnect
    assert_nothing_thrown do
      client.export :database => DB, :user => 'admin', :password => 'admin', :file => given_filename
    end
    # unknow DB
    assert_raise Orientdb4r::UnauthorizedError do
      client.export :database => 'unknown', :user => 'admin', :password => 'admin'
    end
    # bad password
    assert_raise Orientdb4r::UnauthorizedError do
      client.export :database => DB, :user => 'admin', :password => 'unknown'
    end
  end

end
