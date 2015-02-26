require 'test_helper'

###
# This class tests communication with OrientDB cluster and load balancing.
class TestLoadBalancing < Test::Unit::TestCase

  ###
  # Test default Sequence strategy.
  def test_sequence_loadbalancing
    client = Orientdb4r.client :nodes => [{}, {:port => 2481}], :instance => :new
    assert_equal :sequence, client.load_balancing
    lb_strategy = client.lb_strategy
    assert_not_nil lb_strategy
    assert_instance_of Orientdb4r::Sequence, lb_strategy
    assert_equal 0, lb_strategy.node_index
    assert_equal 0, lb_strategy.node_index
    assert_equal client.nodes[0], client.nodes[client.lb_strategy.node_index]
    assert_equal client.nodes[0], client.nodes[client.lb_strategy.node_index]
  end

  ###
  # Test RoundRobin strategy.
  def test_roundrobin_loadbalancing
    client = Orientdb4r.client :nodes => [{}, {:port => 2481}], :load_balancing => :round_robin, :instance => :new
    assert_equal :round_robin, client.load_balancing
    lb_strategy = client.lb_strategy
    assert_not_nil lb_strategy
    assert_instance_of Orientdb4r::RoundRobin, lb_strategy
    assert_equal 0, lb_strategy.node_index
    assert_equal 1, lb_strategy.node_index
    assert_equal 0, lb_strategy.node_index
    assert_equal client.nodes[1], client.nodes[client.lb_strategy.node_index]
    assert_equal client.nodes[0], client.nodes[client.lb_strategy.node_index]
    assert_equal client.nodes[1], client.nodes[client.lb_strategy.node_index]
  end

  ###
  # Tests variant reasons for LB failure.
  def test_load_balancing_in_problems
    # invalid port
    client = Orientdb4r.client :port => 9999, :instance => :new
    assert_raise Orientdb4r::ConnectionError do
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    end
    # opened port, but not REST
    client = Orientdb4r.client :port => 2424, :instance => :new
    assert_raise Orientdb4r::ConnectionError do
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    end

    # invalid ports - both
    client = Orientdb4r.client :nodes => [{:port => 9998}, {:port => 9999}], :instance => :new
    begin
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
      assert_equal 0, 1, "Orientdb4r::ConnectionError EXPECTED"
    rescue Orientdb4r::ConnectionError => e
      assert_equal 'all nodes failed to communicate with server!', e.message
    end


    # more nodes

    # first node bad, second must work (sequence)
    client = Orientdb4r.client :nodes => [{:port => 2481}, {}], :instance => :new
    assert_nothing_thrown do # there has to be ERROR in log
      client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    end
    assert_equal 1, client.lb_strategy.bad_nodes.size
    assert client.lb_strategy.bad_nodes.include? 0

    # second node bad => second call has to be realized by first one (round robin)
    client = Orientdb4r.client :nodes => [{}, {:port => 2481}], :load_balancing => :round_robin, :instance => :new
    assert client.lb_strategy.bad_nodes.empty?
    client.connect :database => 'temp', :user => 'admin', :password => 'admin'
    assert client.lb_strategy.bad_nodes.empty?
    client.query 'SELECT FROM OUser'
    assert_equal 1, client.lb_strategy.bad_nodes.size
    assert client.lb_strategy.bad_nodes.include? 1
  end

end
