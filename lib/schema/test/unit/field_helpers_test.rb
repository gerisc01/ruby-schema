require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'

class FieldHelpersTest < Minitest::Test

  def setup
    @test_class = Class.new
  end

  def teardown
    @test_class = nil
  end

  def test_field_conversion_string
    field = Field.from_object('', {:type => String})
    initial_value = "A String"
    field_type = FieldHelpers.generic_to_field_type(field, initial_value)
    assert_equal "A String", field_type

    generic = FieldHelpers.field_type_to_generic(field, field_type)
    assert_equal initial_value, generic
  end

  def test_field_conversion_integer
    field = Field.from_object('', {:type => Integer})
    initial_value = 25
    field_type = FieldHelpers.generic_to_field_type(field, initial_value)
    assert_equal 25, field_type

    generic = FieldHelpers.field_type_to_generic(field, field_type)
    assert_equal initial_value, generic
  end

  def test_field_conversion_schema_ref
    TestHelpers.create_schema_with_fields(@test_class, {'test_field' => {:required => false}})
    field = Field.from_object('', {:type => @test_class})
    initial_value = {'id' => '1', 'test_field' => 'Something'}
    field_type = FieldHelpers.generic_to_field_type(field, initial_value)
    assert_equal @test_class.new(initial_value), field_type

    generic = FieldHelpers.field_type_to_generic(field, field_type)
    assert_equal initial_value, generic
  end

end