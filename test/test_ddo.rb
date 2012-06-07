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
  # CREATE TABLE
  def test_create_class
    assert_nothing_raised do @client.create_class(CLASS); end
    # already exist
    assert_raise Orientdb4r::OrientdbError do @client.create_class(CLASS); end

    # the class is visible in class list delivered by connect
    rslt = @client.connect :database => @database, :user => 'admin', :password => 'admin'
    assert 1 == rslt['classes'].select { |i| i['name'] == CLASS }.size

    # create with :force=>true
    assert_nothing_raised do @client.create_class(CLASS, :force => true); end
  end


  ###
  # CREATE TABLE ... EXTENDS
  def test_create_class_extends
    assert_nothing_raised do @client.create_class(CLASS, :extends => 'OUser'); end
    rslt = @client.connect :database => @database, :user => 'admin', :password => 'admin'
    clazz_info = rslt['classes'].select { |i| i['name'] == CLASS }
    assert 1 == clazz_info.size
    assert 'OUser' == clazz_info[0]['superClass']

    assert_raise Orientdb4r::OrientdbError do @client.create_class(CLASS, :extends => 'nonExistingSuperClass'); end
  end


  ###
  # DROP TABLE
  def test_drop_table
    assert_nothing_raised do @client.drop_class(CLASS); end

    # the class is visible in class list delivered by connect
    rslt = @client.connect :database => @database, :user => 'admin', :password => 'admin'
    assert rslt['classes'].select { |i| i['name'] == CLASS }.empty?
  end


  def test_create_class_with_properties
    assert_nothing_raised do
      @client.create_class(CLASS) do |c|
        c.property
      end
    end
  end

end
