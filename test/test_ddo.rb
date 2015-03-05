require 'test_helper'

###
# This class tests Data Definition Operarions.
class TestDdo < Test::Unit::TestCase

  CLASS = 'testing'
  DB = 'temp'

  def initialize(params)
    super params
    @client = Orientdb4r.client
  end

  def setup
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
  end

  def teardown
    # remove the testing class after each test
    @client.drop_class(CLASS, :mode => :strict)
    @client.disconnect
  end


  ###
  # GET - Class
  def test_get_class
    assert_nothing_thrown do ouser = @client.get_class 'OUser'; end
    # class does not exist
    assert_raise Orientdb4r::NotFoundError do @client.get_class 'OUserXXX'; end

    clazz = @client.get_class 'OUser'
    # test OClass
    assert_equal 'OUser', clazz.name
    assert_nothing_thrown do clazz.properties; end
    assert_instance_of Array, clazz.properties
    assert !clazz.properties.empty?
    assert_nothing_thrown do clazz.property(:password); end
    assert_raise ArgumentError do clazz.property(:unknown_prop); end
    assert_equal 'OIdentity', clazz.super_class
    assert_instance_of Array, clazz.clusters
    assert !clazz.clusters.empty?
    assert_not_nil clazz.default_cluster
    assert clazz.kind_of? Orientdb4r::OClass
    assert !clazz.abstract?
    # test Property
    prop = clazz.property :password
    assert_equal 'password', prop.name
    assert_equal 'STRING', prop.type
    assert prop.mandatory
    assert prop.not_null
    assert_nil prop.min
    assert_nil prop.min
    assert prop.kind_of? Orientdb4r::Property

    assert @client.class_exists?('OUser')
    assert !@client.class_exists?('UnknownClass')
  end


  ###
  # CREATE CLASS
  def test_create_class
    assert !@client.class_exists?(CLASS)
    assert_nothing_thrown do @client.create_class(CLASS); end
    assert @client.class_exists?(CLASS)
    assert_nothing_thrown do @client.get_class(CLASS); end # raises an Error if no class found
    # already exist
    assert_raise Orientdb4r::ServerError do @client.create_class(CLASS); end

    # create with :force=>true
    assert_nothing_thrown do @client.create_class(CLASS, :force => true); end
    assert_nothing_thrown do @client.get_class(CLASS); end

    # create ABSTRACT
    ab_class = 'testingAbstr'
    assert_nothing_thrown do @client.create_class(ab_class, :abstract => true); end
    clazz = @client.get_class ab_class
    assert clazz.abstract?
    assert_raise Orientdb4r::ServerError do @client.create_document({ '@class' => ab_class, 'prop1' => 1 }); end
    # clean up
    @client.drop_class(ab_class, :mode => :strict)
  end


  ###
  # CREATE CLASS ... EXTENDS
  def test_create_class_extends
    assert_nothing_thrown do @client.create_class(CLASS, :extends => 'OUser'); end
    assert_nothing_thrown do @client.get_class(CLASS); end
    clazz = @client.get_class(CLASS)
    assert_equal 'OUser', clazz.super_class

    # bad super class
    assert_raise Orientdb4r::ServerError do @client.create_class(CLASS, :extends => 'nonExistingSuperClass'); end
  end


  ###
  # DROP TABLE
  def test_drop_class
    super_clazz = "#{CLASS}Sup"
    @client.drop_class(super_clazz); # just to be sure if previous test failed
    @client.create_class(super_clazz);
    @client.create_class(CLASS);
    assert_nothing_thrown do @client.drop_class(CLASS); end
    assert_raise Orientdb4r::NotFoundError do @client.get_class(CLASS); end # no info more
    # the class is not visible in class list delivered by connect
    db_info = @client.get_database
    assert db_info['classes'].select { |i| i.name == CLASS }.empty?

    # CLASS extends super_class
    @client.create_class(CLASS, :extends => super_clazz);
    assert_raise Orientdb4r::OrientdbError do @client.drop_class(super_clazz, :mode => :strict); end
    assert_nothing_thrown do @client.get_class(super_clazz); end # still there
    @client.drop_class(CLASS);
    assert_nothing_thrown do @client.drop_class(super_clazz, :mode => :strict); end
  end


  ###
  # CREATE PROPERTY
  def test_create_property
    @client.create_class(CLASS)
    assert_nothing_thrown do @client.create_property(CLASS, 'prop1', :integer); end
    clazz = @client.get_class(CLASS)
    assert_equal 'INTEGER', clazz.property(:prop1).type
    assert_nil clazz.property(:prop1).linked_class

    # already exist
    assert_raise Orientdb4r::ServerError do @client.create_property(CLASS, 'prop1', :integer); end
  end


  ###
  # CREATE PROPERTY (linked-type)
  def test_create_linkedtype
    @client.create_class(CLASS)
    assert_nothing_thrown do @client.create_property(CLASS, 'friends', :linkset, :linked_class => 'OUser'); end
    clazz = @client.get_class(CLASS)
    assert_equal 'LINKSET', clazz.property(:friends).type
    assert_equal 'OUser', clazz.property(:friends).linked_class

    # unknow linked-class
    assert_raise Orientdb4r::ServerError do
      @client.create_property(CLASS, 'friends2', :linkset, :linked_class => 'UnknownClass')
    end

    # already exist
    assert_raise Orientdb4r::ServerError do
      @client.create_property(CLASS, 'friends', :linkset, :linked_class => 'OUser');
    end
  end


  ###
  # CREATE CLASS + PROPERTY
  def test_create_class_with_properties
    assert_nothing_thrown do
      @client.create_class(CLASS) do |c|
        c.property 'prop1', :integer
        c.property 'prop2', :string, :mandatory => true, :notnull => true, :readonly => true, :min => 1, :max => 99
        c.link     'user',  :linkset, 'OUser', :mandatory => true
      end
    end

    clazz = @client.get_class(CLASS)
    assert_equal 3, clazz.properties.size

    prop1 = clazz.property(:prop1)
    assert_equal 'INTEGER', prop1.type
    assert !prop1.mandatory
    assert !prop1.not_null
    assert !prop1.read_only
    assert_nil prop1.min
    assert_nil prop1.max
    assert_nil prop1.linked_class

    prop2 = clazz.property(:prop2)
    assert_equal 'STRING', prop2.type
    assert prop2.mandatory
    assert prop2.not_null
    assert prop2.read_only
    assert_equal '1', prop2.min
    assert_equal '99',  prop2.max
    assert_nil prop2.linked_class

    user = clazz.property(:user)
    assert_equal 'LINKSET', user.type
    assert user.mandatory
    assert !user.not_null
    assert !user.read_only
    assert_nil user.min
    assert_nil user.max
    assert_equal 'OUser', user.linked_class


    # properties direct as parametr
    @client.drop_class CLASS
    assert_nothing_thrown do
      @client.create_class(CLASS, :properties => [
          { :property => 'prop1_q', :type => :integer },
          { :property => 'prop2_q', :type => :string, :mandatory => true, :notnull => true, :min => 1, :max => 99 },
          { :property => 'user_q',  :type => :linkset, :linked_class => 'OUser', :mandatory => true }
      ])
    end

    clazz = @client.get_class(CLASS)
    assert_equal 3, clazz.properties.size

    prop1 = clazz.property(:prop1_q)
    assert_equal 'INTEGER', prop1.type
    assert !prop1.mandatory
    assert !prop1.not_null
    assert_nil prop1.min
    assert_nil prop1.max
    assert_nil prop1.linked_class

    prop2 = clazz.property(:prop2_q)
    assert_equal 'STRING', prop2.type
    assert prop2.mandatory
    assert prop2.not_null
    assert_equal '1', prop2.min
    assert_equal '99',  prop2.max
    assert_nil prop2.linked_class

    user = clazz.property(:user_q)
    assert_equal 'LINKSET', user.type
    assert user.mandatory
    assert !user.not_null
    assert_nil user.min
    assert_nil user.max
    assert_equal 'OUser', user.linked_class
  end

end
