require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class HashFieldsTest < Minitest::Test

  def setup
    @test_class = Class.new
    fields = {
      'values' => {:type => Hash},
      'ints' => {:type => Hash, :subtype => Integer},
      'strings' => {:type => Hash, :subtype => String, :required => true},
    }
    TestHelpers.create_schema_with_fields(@test_class, fields)

    @empty_hash = {}
    @nil_hash = {nil => nil}
    @ints_hash = {'1' => 1, '2' => 2}
    @strings_hash = {'1' => 'a', '2' => 'b', '3' => 'c'}
  end

  def teardown
    @test_class = nil
  end

  def test_getter
    instance = @test_class.new({'ints' => {}, 'strings' => {'1' => 'a', '2' => 'b', '3' => 'c'}})
    assert_nil instance.values
    assert_equal @empty_hash, instance.ints
    assert_equal @strings_hash, instance.strings
  end

  def test_adding_pairs
    instance = @test_class.new
    instance.upsert_value(nil, nil)
    instance.upsert_int('1', 1)
    instance.upsert_int('2', 2)
    instance.upsert_string('1', 'a')
    instance.upsert_string('2', 'b')
    instance.upsert_string('3', 'c')
    assert_equal @nil_hash, instance.values
    assert_equal @ints_hash, instance.ints
    assert_equal @strings_hash, instance.strings
  end

  def test_removing_pairs
    instance = @test_class.new({'ints' => {'1' => 1, '2' => 2}, 'strings' => {'1' => 'a', '2' => 'b', '3' => 'c'}})
    # Ignores it if it doesn't have the value
    instance.remove_value('1')
    # Successfully removes it if it does
    instance.remove_int('1')
    instance.remove_int('2')
    instance.remove_string('1')
    updated_strings = {'2' => 'b', '3' => 'c'}
    assert_nil instance.values
    assert_equal @empty_hash, instance.ints
    assert_equal updated_strings, instance.strings
  end

  def test_setter_wrong_type
    instance = @test_class.new
    assert_raises(Schema::ValidationError) do
      instance.upsert_int('1', 'a')
    end
    assert_raises(Schema::ValidationError) do
      instance.upsert_string('1', 1)
    end
  end

end