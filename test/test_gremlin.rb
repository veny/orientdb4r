require 'test_helper'

###
# This class tests Data Manipulation Operarions.
class TestGremlin < Test::Unit::TestCase
  include Orientdb4r::Utils

  CLASS = 'testing'
  DB = 'temp'

  def setup
    @client = Orientdb4r.client
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
    @client.gremlin("g.V.has('@class','#{CLASS}').remove()")
    @client.drop_class(CLASS) # just to be sure if the previous test failed
  end

  def teardown
    # remove the testing class after each test
    @client.gremlin("g.V.has('@class','#{CLASS}').remove()")
    @client.drop_class(CLASS)
    @client.disconnect
  end

  def test_gremlin

    1.upto(25) do |i|
      result = @client.gremlin("g.addVertex('class:#{CLASS}', 'prop1', 1, 'prop2', 'string1')")
    end

    entries = @client.gremlin("g.V.has('@class','#{CLASS}')[0..<20]")
    assert_not_nil entries
    assert_instance_of Array, entries
    assert_equal 20, entries.size # no limit20 is default limit
    entries.each { |doc| assert doc.kind_of? Orientdb4r::DocumentMetadata }
    entries.each { |doc| assert_instance_of Orientdb4r::Rid, doc.doc_rid }
    # limit
    assert_equal 5, @client.gremlin("g.V.has('@class', '#{CLASS}')[0..<5]").size
    entries = @client.gremlin("g.V.has('@class', '#{CLASS}')[0..<100]")
    assert_equal 25, entries.size

    assert_equal 25, @client.gremlin("g.V.has('@class', '#{CLASS}').has('prop1', 1)").size
    assert_equal 0,  @client.gremlin("g.V.has('@class', '#{CLASS}').has('prop1', -1)").size

    entries = @client.gremlin "g.v(0:1111)"
    assert_not_nil entries
    assert_instance_of Array, entries

    assert entries.empty?
  end

end
