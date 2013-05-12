require 'test/unit'
require 'orientdb4r'

###
# This class tests Utils methods.
class TestUtils < Test::Unit::TestCase
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

    # :optional cannot be set as default value
    opt_pattern = {:a => :optional, :b => 'B'}
    options = {}
    verify_and_sanitize_options(options, opt_pattern)
    assert_equal 1, options.size
    assert !options.include?(:a)
    assert_equal 'B', options[:b]
  end

  def test_compare_versions
    assert_raise ArgumentError do compare_versions 'foo', 'bar'; end
    assert_raise ArgumentError do compare_versions nil, 'bar'; end
    assert_raise ArgumentError do compare_versions 'foo', nil; end
    assert_raise ArgumentError do compare_versions '1.0.0', 'bar'; end
    assert_raise ArgumentError do compare_versions 'foo', '1.0.0'; end
    assert_nothing_thrown do compare_versions '1.0.0', '1.1.0'; end

    assert_equal 0, compare_versions('1.0.0', '1.0.0')
    assert_equal 0, compare_versions('1.2.0', '1.2.0')
    assert_equal 0, compare_versions('1.2.3', '1.2.3')

    assert_equal 1, compare_versions('1.0.1', '1.0.0')
    assert_equal 1, compare_versions('1.1.0', '1.0.0')
    assert_equal 1, compare_versions('2.0.0', '1.0.0')

    assert_equal -1, compare_versions('1.0.0', '1.0.1')
    assert_equal -1, compare_versions('1.0.0', '1.1.0')
    assert_equal -1, compare_versions('1.0.0', '2.0.0')

    # test block
    tmp = -100;
    compare_versions('1.0.0', '1.0.0') { |comp| tmp = comp }
    assert_equal 0, tmp
    compare_versions('1.0.0', '2.0.0') { |comp| tmp = comp }
    assert_equal -1, tmp
    compare_versions('3.0.0', '2.0.0') { |comp| tmp = comp }
    assert_equal 1, tmp
  end

end
