require 'test/unit'
require 'orientdb4r'

###
# This class tests communication with OrientDB cluster and load balancing.
class TestDatabase < Test::Unit::TestCase

  Orientdb4r::logger.level = Logger::DEBUG


  ###
  # CONNECT
  def test_nodes
    client = Orientdb4r.client :nodes => [{}, {:port => 2481}]
    assert_not_nil client.nodes
    assert_instance_of Array, client.nodes
    assert_equal 2, client.nodes.size

  end

end
