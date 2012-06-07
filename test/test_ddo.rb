require 'test/unit'
require 'orientdb4r'

###
# This class tests Data Definition Operarions.
class TestRest < Test::Unit::TestCase

  CLASS = 'testing'

  def initialize(params)
    super params
#    @database = (0...8).map{65.+(rand(25)).chr}.join
    @database = 'temp'

    @client = Orientdb4r.client
#    @client.create_database :database => @database, :user => 'root', :password => 'root'
  end

  def setup
    @client.connect :database => @database, :user => 'admin', :password => 'admin'
  end

  def teardown
    # remove the testing class after each test
    @client.drop_class(CLASS)
    @client.disconnect
  end


  ###
  # GET - Class
  def test_get_class
    ouser = {}
    assert_nothing_raised do ouser = @client.get_class 'OUser'; end
    assert 'OUser' == ouser['name']
    # class does not exist
    assert_raise ArgumentError do @client.get_class 'OUserXXX'; end
  end


  ###
  # CREATE TABLE
  def test_create_class
    assert_nothing_raised do @client.create_class(CLASS); end
    assert_nothing_raised do @client.get_class(CLASS); end
    # already exist
    assert_raise Orientdb4r::OrientdbError do @client.create_class(CLASS); end

    # create with :force=>true
    assert_nothing_raised do @client.create_class(CLASS, :force => true); end
    assert_nothing_raised do @client.get_class(CLASS); end
  end


  ###
  # CREATE TABLE ... EXTENDS
  def test_create_class_extends
    assert_nothing_raised do @client.create_class(CLASS, :extends => 'OUser'); end
    assert_nothing_raised do @client.get_class(CLASS); end

    # bad super class
    assert_raise Orientdb4r::OrientdbError do @client.create_class(CLASS, :extends => 'nonExistingSuperClass'); end
  end


  ###
  # DROP TABLE
  def test_drop_table
    assert_nothing_raised do @client.drop_class(CLASS); end

    # the class is not visible in class list delivered by connect
    rslt = @client.connect :database => @database, :user => 'admin', :password => 'admin'
    assert rslt['classes'].select { |i| i['name'] == CLASS }.empty?
  end


  ###
  # CREATE PROPERTY
  def test_create_property
    @client.create_class(CLASS)
    assert_nothing_raised do @client.create_property(CLASS, 'prop1', :integer); end

    # already exist
    assert_raise Orientdb4r::OrientdbError do @client.create_property(CLASS, 'prop1', :integer); end
  end


  def test_create_class_with_properties
    assert_nothing_raised do
      @client.create_class(CLASS) do |c|
        c.property
      end
    end
  end

end
