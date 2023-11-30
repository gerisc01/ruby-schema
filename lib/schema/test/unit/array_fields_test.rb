require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class ArrayFieldsTest < Minitest::Test

  def setup
    @test_class = Class.new
    fields = {
      'values' => {:type => Array},
      'ints' => {:type => Array, :subtype => Integer},
      'strings' => {:type => Array, :subtype => String, :required => true},
    }
    TestHelpers.create_schema_with_fields(@test_class, fields)
  end

  def teardown
    @test_class = nil
  end

  def test_getter
    instance = @test_class.new({'ints' => [], 'strings' => ['a', 'b', 'c']})
    assert_nil instance.values
    assert_equal [], instance.ints
    assert_equal ['a', 'b', 'c'], instance.strings
  end

  def test_adding_values
    instance = @test_class.new
    instance.add_value(nil)
    instance.add_int(1)
    instance.add_int(2)
    instance.add_string('a')
    instance.add_string('b')
    instance.add_string('c')
    assert_equal [nil], instance.values
    assert_equal [1, 2], instance.ints
    assert_equal ['a', 'b', 'c'], instance.strings
  end

  def test_removing_values
    instance = @test_class.new({'ints' => [1, 2], 'strings' => ['a', 'b', 'c']})
    # Ignores it if it doesn't have the value
    instance.remove_value(1)
    # Successfully removes it if it does
    instance.remove_int(1)
    instance.remove_int(2)
    instance.remove_string('a')
    assert_nil instance.values
    assert_equal [], instance.ints
    assert_equal ['b', 'c'], instance.strings
  end

  def test_setter_wrong_type
    instance = @test_class.new
    assert_raises(Schema::ValidationError) do
      instance.add_int('a')
    end
    assert_raises(Schema::ValidationError) do
      instance.add_string(1)
    end
  end

end