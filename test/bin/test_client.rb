require 'test_helper'

###
# This class tests communication with OrientDB cluster and load balancing.
# Note: Test of binary communication.
class TestBinDatabase < Test::Unit::TestCase

  DB = 'temp'
#Orientdb4r::logger.level = Logger::DEBUG

  def setup
    @client = Orientdb4r.client :binary => true
  end

  ###
  # CONNECT
  def test_connect
    assert_nothing_thrown do @client.connect :database => DB, :user => 'admin', :password => 'admin'; end
  end

end
