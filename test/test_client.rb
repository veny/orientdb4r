require 'test/unit'
$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'orientdb4r'
require 'coveralls'
Coveralls.wear!

###
# This class tests communication with OrientDB cluster and load balancing.
class TestClient < Test::Unit::TestCase

  Orientdb4r::logger.level = Logger::DEBUG

  PROXY_URL = 'http://bad.domain.com'


  ###
  # Test inintialization of single node.
  def test_one_node_initialization
    client = Orientdb4r.client :instance => :new
    assert_not_nil client.nodes
    assert_instance_of Array, client.nodes
    assert_equal 1, client.nodes.size
    assert_equal 2480, client.nodes[0].port
    assert_equal false, client.nodes[0].ssl
  end

  ###
  # Test inintialization of more nodes.
  def test_nodes_initialization
    client = Orientdb4r.client :nodes => [{}, {:port => 2481}], :instance => :new
    assert_not_nil client.nodes
    assert_instance_of Array, client.nodes
    assert_equal 2, client.nodes.size
    assert_equal 2480, client.nodes[0].port
    assert_equal 2481, client.nodes[1].port
    assert_equal false, client.nodes[0].ssl
    assert_equal false, client.nodes[1].ssl

    client = Orientdb4r.client :nodes => [{}, {:port => 2481}, {:port => 2482}], :instance => :new
    assert_equal 3, client.nodes.size
  end

  ###
  # Tests initialization of connection library.
  def test_connection_library
    # restclient
    client = Orientdb4r.client :instance => :new
    assert_equal :restclient, client.connection_library
    assert_instance_of Orientdb4r::RestClientNode, client.nodes[0]

    # excon
    if Gem::Specification::find_all_by_name('excon').any?
      client = Orientdb4r.client :connection_library => :excon, :instance => :new
      assert_equal :excon, client.connection_library
      assert_instance_of Orientdb4r::ExconNode, client.nodes[0]
    end
  end

  ###
  # Tests initialization of proxy.
  def test_proxy
    # no proxy - resclient
    client = Orientdb4r.client :instance => :new
    assert_nil client.proxy
    assert_nil RestClient.proxy

    # proxy - restclient
    client = Orientdb4r.client :proxy => PROXY_URL, :instance => :new
    assert_equal PROXY_URL, client.proxy
    assert_equal PROXY_URL, RestClient.proxy
    assert_raise Orientdb4r::ConnectionError do
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    end
    RestClient.proxy = nil # restore no setting

    if Gem::Specification::find_all_by_name('excon').any?
      # no proxy - excon
      client = Orientdb4r.client :connection_library => :excon, :instance => :new
      assert_nil client.proxy
      assert_nil client.nodes[0].proxy

      # proxy - excon
      client = Orientdb4r.client :connection_library => :excon, :proxy => PROXY_URL, :instance => :new
      assert_equal PROXY_URL, client.proxy
      assert_equal PROXY_URL, client.nodes[0].proxy
      assert_raise Orientdb4r::ConnectionError do
        client.connect :database => 'temp', :user => 'admin', :password => 'admin'
      end
    end
  end
end
