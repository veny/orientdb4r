require 'test/unit'
$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'orientdb4r'

###
# This class tests CRUD operarions on document.
class TestDocumentCrud < Test::Unit::TestCase
  include Orientdb4r::Utils

  CLASS = 'testing'
  DB = 'temp'
  Orientdb4r::logger.level = Logger::DEBUG


  def setup
    @client = Orientdb4r.client
    @client.connect :database => DB, :user => 'admin', :password => 'admin'
    @client.create_class(CLASS) do |c|
      c.property 'prop1', :integer, :notnull => :true, :min => 1, :max => 99
      c.property 'prop2', :string, :mandatory => true
    end
  end

  def teardown
    # remove the testing class after each test
    @client.drop_class(CLASS)
    @client.disconnect
  end


  ###
  # CREATE
  def test_create_document
    assert_nothing_thrown do @client.create_document( { '@class' => CLASS, 'prop1' => 99, 'prop2' => 'ipsum lorem' }); end
    doc = @client.create_document({ '@class' => CLASS, 'prop1' => 1, 'prop2' => 'text' })
    assert_instance_of Hash, doc
    assert_not_nil doc.doc_rid
    assert_instance_of Orientdb4r::Rid, doc.doc_rid
    assert_equal CLASS, doc.doc_class
    assert_equal 0, doc.doc_version

    # no effect if a define the version
    doc = @client.create_document({ '@class' => CLASS, '@version' => 2, 'prop1' => 1, 'prop2' => 'text' })
    assert_equal 0, doc.doc_version

    # no effect if an unknown class
    doc = @client.create_document({ '@class' => 'unknown_class', 'a' => 11, 'b' => 'text1' })
    assert_equal 'unknown_class', doc.doc_class
    assert_equal 11, doc['a']
    assert_equal 'text1', doc['b']
    # or missing class
    assert_nothing_thrown do @client.create_document({ 'a' => 1, 'b' => 'text' }); end

    # no mandatory property
    assert_raise Orientdb4r::DataError do @client.create_document({ '@class' => CLASS, 'prop1' => 1 }); end
    # notNull is null, or lesser/bigger
    assert_raise Orientdb4r::DataError do
      @client.create_document({ '@class' => CLASS, 'prop1' => nil, 'prop2' => 'text' })
    end
    assert_raise Orientdb4r::DataError do
      @client.create_document({ '@class' => CLASS, 'prop1' => 0, 'prop2' => 'text' })
    end
    assert_raise Orientdb4r::DataError do
      @client.create_document({ '@class' => CLASS, 'prop1' => 100, 'prop2' => 'text' })
    end
  end

  ###
  # GET
  def test_get_document
    created = @client.create_document( { '@class' => CLASS, 'prop1' => 1, 'prop2' => 'text' })

    doc = @client.get_document created.doc_rid
    assert_equal CLASS, doc.doc_class
    assert_equal created.doc_rid, doc.doc_rid
    assert_equal 0, doc.doc_version
    assert_equal 'd', doc.doc_type
    assert_equal 1, doc['prop1']
    assert_equal 'text', doc['prop2']
    assert_nil doc['unknown_property']
    assert doc.kind_of? Orientdb4r::DocumentMetadata

    # not existing RID
    rid1 = Orientdb4r::Rid.new("#{created.doc_rid.cluster_id}:#{created.doc_rid.document_id + 1}") # '#6:0' > '#6:1' or '#6:11' > '#6:12'
    assert_raise Orientdb4r::NotFoundError do @client.get_document rid1; end
    # bad RID format
    assert_raise ArgumentError do @client.get_document('xx'); end
  end

  ###
  # UPDATE
  def test_update_document
    created = @client.create_document( { '@class' => CLASS, 'prop1' => 1, 'prop2' => 'text' })
    doc = @client.get_document created.doc_rid

    doc['prop1'] = 2
    doc['prop2'] = 'unit'
    assert_nothing_thrown do @client.update_document doc; end
    doc = @client.get_document created.doc_rid
    assert_equal 2, doc['prop1']
    assert_equal 'unit', doc['prop2']

    # bad version
    doc = @client.get_document created.doc_rid
    doc['prop1'] = 222 # a property has to be changed to server engine sees a difference
    doc['@version'] = 2
    assert_raise Orientdb4r::DataError do @client.update_document doc; end

    # class cannot be changed
    doc = @client.get_document created.doc_rid
    doc['@class'] = 'OUser'
    assert_nothing_thrown do @client.update_document doc; end
    assert_equal CLASS, @client.get_document(created.doc_rid).doc_class

    # no mandatory property
    doc = @client.get_document created.doc_rid
    doc.delete 'prop2'
    assert_raise Orientdb4r::DataError do @client.update_document doc; end
    # notNull is null, or lesser/bigger
    doc = @client.get_document created.doc_rid
    doc['prop1'] = nil
    assert_raise Orientdb4r::DataError do @client.update_document doc; end
  end


  ###
  # DELETE
  def test_delete_document
    doc = @client.create_document( { '@class' => CLASS, 'prop1' => 1, 'prop2' => 'text' })
    assert_not_nil doc

    assert_nothing_thrown do @client.delete_document doc.doc_rid; end
    assert_raise Orientdb4r::NotFoundError do @client.get_document doc.doc_rid; end

    # already deleted
    assert_raise Orientdb4r::NotFoundError do @client.delete_document doc.doc_rid; end

    # not existing RID
    assert_raise Orientdb4r::NotFoundError do @client.delete_document '#4:1111'; end
    # bad RID format
    assert_raise ArgumentError do @client.delete_document 'xx'; end
  end

end
