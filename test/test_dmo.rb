require 'test/unit'
require 'orientdb4r'

###
# This class tests Data Manipulation Operarions.
class TestDmo < Test::Unit::TestCase
  include Orientdb4r::Utils

  CLASS = 'testing'
  DB = 'temp'
  Orientdb4r::DEFAULT_LOGGER.level = Logger::DEBUG


  def setup
    @client = Orientdb4r.client
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
    @client.create_class(CLASS) do |c|
      c.property 'prop1', :integer
      c.property 'prop2', :string, :mandatory => true, :notnull => :true, :min => 1, :max => 99
    end
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
        @client.command "INSERT INTO #{CLASS} (prop1, prop2) VALUES (#{i}, '#{random_string}')"
      end
    end

    assert_equal 10, @client.query("SELECT count(*) FROM #{CLASS}")[0]['count'].to_i
  end


  ###
  # SELECT
  def test_query
    1.upto(10) do |i|
      @client.command "INSERT INTO #{CLASS} (prop1, prop2) VALUES (#{i}, 'string#{i}')"
    end

    puts @client.query("SELECT count(*) FROM #{CLASS}")
  end

end
