require 'test_helper'

###
# This class tests Data Manipulation Operarions.
class TestDmo < Test::Unit::TestCase
  include Orientdb4r::Utils

  CLASS = 'testing'
  DB = 'temp'

  def setup
    @client = Orientdb4r.client
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
    @client.drop_class(CLASS) # just to be sure if the previous test failed
    @client.create_class(CLASS) do |c|
      c.property 'prop1', :integer
      c.property 'prop2', :string, :mandatory => true, :notnull => :true, :min => 1, :max => 99
      c.link     'friends',  :linkset, 'OUser', :mandatory => true
    end
    @admin = @client.query("SELECT FROM OUser WHERE name = 'admin'")[0]
  end

  def teardown
    # remove the testing class after each test
    @client.drop_class(CLASS)
    @client.disconnect
  end


  ###
  # INSERT INTO
  def test_insert
    assert_nothing_thrown do
      1.upto(10) do |i|
        @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (#{i}, '#{random_string}', [#{@admin['@rid']}])"
      end
    end

    entries = @client.query("SELECT FROM #{CLASS}")
    assert_equal 10, entries.size
    assert_equal 10, entries.select { |e| e if e['prop1'] <= 10 }.size
    assert_equal 10, entries.select { |e| e if e['friends'].size == 1 }.size

    # insert more users into LINKSET
    urids = @client.query('SELECT FROM OUser').collect { |u| u['@rid'] }
    assert_nothing_thrown do
      @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (1, 'linkset', [#{urids.join(',')}])"
    end
    assert_equal urids.size, @client.query("SELECT FROM #{CLASS} WHERE prop2 = 'linkset'")[0]['friends'].size

    # table doesn't exist
    assert_raise Orientdb4r::InvalidRequestError do
      @client.command "INSERT INTO #{CLASS}x (prop1, prop2, friends) VALUES (1, 'linkset', [#{urids.join(',')}])"
    end
    # bad syntax
    assert_raise Orientdb4r::ServerError do
      @client.command 'xxx'
    end

    # used for SELECT
    assert_equal @client.query('SELECT FROM OUser'), @client.command('SELECT FROM OUser')['result']
  end


  ###
  # SELECT
  def test_query
    1.upto(25) do |i|
      @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (#{i}, 'string#{i}', [#{@admin['@rid']}])"
    end

    entries = @client.query("SELECT FROM #{CLASS}")
    assert_not_nil entries
    assert_instance_of Array, entries
    assert_equal 20, entries.size # 20 is default limit
    entries.each { |doc| assert doc.kind_of? Orientdb4r::DocumentMetadata }
    entries.each { |doc| assert_instance_of Orientdb4r::Rid, doc.doc_rid }
    # limit
    assert_equal 5, @client.query("SELECT FROM #{CLASS} LIMIT 5").size
    entries = @client.query "SELECT FROM #{CLASS}", :limit => 100
    assert_equal 25, entries.size
    assert_raise ArgumentError do @client.query "SELECT FROM #{CLASS}", :unknown => 100; end

    assert_equal 1, @client.query("SELECT FROM #{CLASS} WHERE prop1 = 1").size
    assert_equal 0, @client.query("SELECT FROM #{CLASS} WHERE prop1 = -1").size
    # graph
    rid = @client.query("SELECT FROM #{CLASS} WHERE prop1 = 1")[0]['@rid']
    gr = @client.query("SELECT FROM (TRAVERSE * FROM #{rid})")
    assert_equal 3, gr.size # entries: testing, OUser, ORole
    assert_equal 1, gr.select { |e| e if e['@class'] == CLASS }.size
    assert_equal 1, gr.select { |e| e if e['@class'] == 'OUser' }.size
    assert_equal 1, gr.select { |e| e if e['@class'] == 'ORole' }.size

    # table doesn't exist
    assert_raise Orientdb4r::InvalidRequestError do
      @client.query 'SELECT FROM OUserX'
    end
    # bad syntax
    assert_raise Orientdb4r::ServerError do
      @client.query 'xxx'
    end
    # record not found in existing cluster
    entries = @client.query 'SELECT FROM #0:1111'
    assert_not_nil entries
    assert_instance_of Array, entries
    assert entries.empty?
    # try to find entry in a non-existing cluster
    assert_raise Orientdb4r::NotFoundError do @client.query 'SELECT FROM #111:1111'; end
    # used for INSERT
    assert_raise Orientdb4r::ServerError do
      @client.query "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (0, 'string0', [])"
    end
  end

end
