require 'test/unit'
require 'orientdb4r'

###
# This class tests Data Definition Operarions.
class TestDdo < Test::Unit::TestCase

  CLASS = 'testing'
  DB = 'temp'
  Orientdb4r::logger.level = Logger::DEBUG

  def initialize(params)
    super params

    @client = Orientdb4r.client
  end

  def setup
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
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
    assert_nothing_thrown do ouser = @client.get_class 'OUser'; end
    assert_equal 'OUser', ouser['name']
    # class does not exist
    assert_raise ArgumentError do @client.get_class 'OUserXXX'; end
  end


  ###
  # CREATE TABLE
  def test_create_class
    assert_nothing_thrown do @client.create_class(CLASS); end
    assert_nothing_thrown do @client.get_class(CLASS); end
    # already exist
    assert_raise Orientdb4r::OrientdbError do @client.create_class(CLASS); end

    # create with :force=>true
    assert_nothing_thrown do @client.create_class(CLASS, :force => true); end
    assert_nothing_thrown do @client.get_class(CLASS); end
  end


  ###
  # CREATE TABLE ... EXTENDS
  def test_create_class_extends
    assert_nothing_thrown do @client.create_class(CLASS, :extends => 'OUser'); end
    assert_nothing_thrown do @client.get_class(CLASS); end

    # bad super class
    assert_raise Orientdb4r::OrientdbError do @client.create_class(CLASS, :extends => 'nonExistingSuperClass'); end
  end


  ###
  # DROP TABLE
  def test_drop_table
    assert_nothing_thrown do @client.drop_class(CLASS); end

    # the class is not visible in class list delivered by connect
    rslt = @client.connect :database => DB, :user => 'admin', :password => 'admin'
    assert rslt['classes'].select { |i| i['name'] == CLASS }.empty?
  end


  ###
  # CREATE PROPERTY
  def test_create_property
    @client.create_class(CLASS)
    assert_nothing_thrown do @client.create_property(CLASS, 'prop1', :integer); end
    clazz = @client.get_class(CLASS)
    assert clazz.include? 'properties'
    assert_instance_of Array, clazz['properties']
    props = clazz['properties'].select { |i| i['name'] == 'prop1' }
    assert_equal 1, props.size
    assert_equal 'INTEGER', props[0]['type']

    # already exist
    assert_raise Orientdb4r::OrientdbError do @client.create_property(CLASS, 'prop1', :integer); end
  end


  ###
  # CREATE CLASS + PROPERTY
  def test_create_class_with_properties
    assert_nothing_thrown do
      @client.create_class(CLASS) do |c|
        c.property 'prop1', :integer
        c.property 'prop2', :string, :mandatory => true, :notnull => :true, :min => 1, :max => 99
      end
    end

    clazz = @client.get_class(CLASS)
    assert_equal 2, clazz['properties'].size

    prop1 = clazz['properties'].select { |i| i['name'] == 'prop1' }[0]
    assert_equal 'INTEGER', prop1['type']
    assert !prop1['mandatory']
    assert !prop1['notNull']
    assert prop1['min'].nil?
    assert prop1['max'].nil?

    prop2 = clazz['properties'].select { |i| i['name'] == 'prop2' }[0]
    assert_equal 'STRING', prop2['type']
    assert prop2['mandatory']
    assert prop2['notNull']
    assert_equal '1', prop2['min']
    assert_equal '99',  prop2['max']
  end

end
