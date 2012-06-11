require 'test/unit'
require 'orientdb4r'

###
# This class tests Utils methods.
class TestDmo < Test::Unit::TestCase
  include Orientdb4r::Utils

  def test_verify_options
    opt_pattern = {:a => :mandatory, :b => :optional, :c => 'predefined', :d => [1, false]}
    assert_nothing_thrown do verify_options({:a => 'A', :b => 'B', :c => 'C', :d => 1}, opt_pattern); end

    # missing mandatory
    assert_raise ArgumentError do verify_options({}, opt_pattern); end
    # unknown key
    assert_raise ArgumentError do verify_options({:a => 1, :z => 2}, opt_pattern); end
    # value not in predefined set
    assert_raise ArgumentError do verify_options({:a => 1, :d => 3}, opt_pattern); end
  end

  def test_verify_and_sanitize_options
    opt_pattern = {:a => 'A', :b => 'B'}
    options = {:a => 'X'}
    verify_and_sanitize_options(options, opt_pattern)
    assert_equal 2, options.size
    assert_equal 'X', options[:a]
    assert_equal 'B', options[:b]
  end

end
