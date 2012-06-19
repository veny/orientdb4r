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
        @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (#{i}, '#{random_string}', #{@admin['@rid']})"
      end
    end

    assert_equal 10, @client.query("SELECT count(*) FROM #{CLASS}")[0]['count'].to_i

    # insert more users into LINKSET
    urids = @client.query('SELECT FROM OUser').collect { |u| u['@rid'] }.join ','
    assert_nothing_thrown do
      rid = @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (1, 'linkset', [#{urids}])"
      puts @client.query("SELECT FROm #{CLASS} WHERE prop2 = 'linkset'")[0]
    end

  end


  ###
  # SELECT
  def test_query
    1.upto(10) do |i|
      @client.command "INSERT INTO #{CLASS} (prop1, prop2, friends) VALUES (#{i}, 'string#{i}', #{@admin['@rid']})"
    end

    puts @client.query("SELECT FROM #{CLASS}")
  end

end
