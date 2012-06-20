require 'test/unit'
require 'orientdb4r'

###
# This class tests Data Manipulation Operarions.
class TestDmo < Test::Unit::TestCase
  include Orientdb4r::Utils

  CLASS = 'testing'
  DB = 'temp'
  Orientdb4r::logger.level = Logger::DEBUG


  def setup
    @client = Orientdb4r.client
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
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

  end


  ###
  # SELECT
  def test_query
    1.upto(10) do |i|
      @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (#{i}, 'string#{i}', [#{@admin['@rid']}])"
    end

    assert_equal 10, @client.query("SELECT FROM #{CLASS}").size
    assert_equal 1, @client.query("SELECT FROM #{CLASS} WHERE prop1 = 1").size
    assert_equal 0, @client.query("SELECT FROM #{CLASS} WHERE prop1 = 11").size
    # graph
    rid = @client.query("SELECT FROM #{CLASS} WHERE prop1 = 1")[0]['@rid']
    gr = @client.query("SELECT FROM (TRAVERSE * FROM #{rid})")
    assert_equal 3, gr.size # # entries: testing, OUser, ORole
    assert_equal 1, gr.select { |e| e if e['@class'] == CLASS }.size
    assert_equal 1, gr.select { |e| e if e['@class'] == 'OUser' }.size
    assert_equal 1, gr.select { |e| e if e['@class'] == 'ORole' }.size
  end

end
