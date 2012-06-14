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
    end
  end

  def teardown
    # remove the testing class after each test
    @client.drop_class(CLASS)
    @client.disconnect
  end


  ###
  # GET
  def test_get_document
    rid = @client.create_document( { '@class' => CLASS, 'prop1' => 1, 'prop2' => 'text' })

    doc = @client.get_document rid
    assert_equal CLASS, doc.doc_class
    assert_equal rid, doc.doc_rid
    assert_equal 0, doc.doc_version
    assert_equal 'd', doc.doc_type

    rid1 = rid.sub(/[0-9]+$/, (rid.split(':')[1].to_i + 1).to_s) # '#6:0' > '#6:1' or '#6:11' > '#6:12'
    doc = @client.get_document rid1
puts doc

  end


end
