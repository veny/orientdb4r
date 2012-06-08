require 'test/unit'
require 'orientdb4r'

###
# This class tests Data Manipulation Operarions.
class TestDmo < Test::Unit::TestCase

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


  def test_insert
    @client.command "INSERT INTO #{CLASS} (prop1, prop2) VALUES (1, 'test')"

    puts @client.query "SELECT FROM #{CLASS}"
  end

end
