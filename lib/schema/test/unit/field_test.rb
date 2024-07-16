require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class FieldTest < Minitest::Test

  def setup
    @field = Field.new
    @field.key = 'a-key'
    @field.display_name = 'A Key'
    @field.type = Array
    @field.subtype = String
    @field.required = true
    @field.type_ref = false
    @field.extra_attrs = {}
  end

  def teardown

  end

  def test_to_schema_object_basic
    expected = {
      'key' => 'a-key',
      'display_name' => 'A Key',
      'type' => Array,
      'subtype' => String,
      'required' => true,
      'type_ref' => false
    }
    assert_equal expected, @field.to_schema_object
  end

  def test_to_schema_object_extra_fields
    @field.extra_attrs = {
      'extra' => 'field',
      'extra2' => 'field2'
    }
    expected = {
      'key' => 'a-key',
      'display_name' => 'A Key',
      'type' => Array,
      'subtype' => String,
      'required' => true,
      'type_ref' => false,
      'extra' => 'field',
      'extra2' => 'field2'
    }
    assert_equal expected, @field.to_schema_object
  end

  def test_from_schema_object_basic
    expected = {
      'key' => 'a-key',
      'display_name' => 'A Key',
      'type' => Array,
      'subtype' => String,
      'required' => true,
      'type_ref' => false
    }
    assert_equal @field.to_schema_object, Field.from_schema_object('a-key', expected).to_schema_object
  end

  def test_from_schema_object_extra_attrs
    @field.extra_attrs = {
      'extra' => 'field',
      'extra2' => 'field2'
    }
    expected = {
      'key' => 'a-key',
      'display_name' => 'A Key',
      'type' => Array,
      'subtype' => String,
      'required' => true,
      'type_ref' => false,
      'extra' => 'field',
      'extra2' => 'field2'
    }
    assert_equal @field.to_schema_object, Field.from_schema_object('a-key', expected).to_schema_object
  end

end