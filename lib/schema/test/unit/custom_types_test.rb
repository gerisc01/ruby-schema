require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class TestCustomType
  def self.field_def_validation(field)
    raise Schema::ValidationError.new("Failed def validation") unless field.extra_attrs[:test] == "valid"
  end

  def self.field_value_validation(field, value)
    if value.is_a?(String) && value == 'valid'
      return true
    elsif value.is_a?(Array) && value.all? { |it| it == "valid" }
      return true
    else
      raise Schema::ValidationError.new("Failed value validation")
    end
  end

  def self.type_match?(value)
    return value.is_a?(String)
  end
end

class CustomTypesTest < Minitest::Test

  def setup
    @test_class = Class.new
  end

  def teardown
  end

  def test_field_boolean
    field = Field.from_schema_object("field", {:type => SchemaType::Boolean})
    # true success
    field.validate(true)
    # false success
    field.validate(false)
    # true string fail
    assert_raises do
      field.validate("true")
    end
  end

  def test_field_date
    field = Field.from_schema_object("field", {:type => SchemaType::Date})
    # date object success
    field.validate(Date.new)
    # date string success
    field.validate("2022-12-31")
    # invalid date string fail
    assert_raises do
      field.validate("2022-12-50")
    end
  end

  def test_custom_type_match_validation
    TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:type => TestCustomType, :test => 'valid'} })
    instance_fail = @test_class.new({'custom' => 2})
    error = assert_raises(Schema::ValidationError) do
      instance_fail.validate
    end
    assert error.message.include?("'custom' is expecting type 'TestCustomType' but found 'Integer'")

    instance_success = @test_class.new({'custom' => 'valid'})
    instance_success.validate
  end

  def test_custom_type_match_validation_notype
    TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:required => true} })
    instance = @test_class.new({'custom' => 'anything'})
    instance.validate
  end

  def test_custom_type_match_validation_array
    TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:type => Array, :subtype => TestCustomType, :test => 'valid'} })
    instance = @test_class.new({'custom' => ['valid', 'valid']})
    instance.validate
  end

  def test_custom_field_definition_validation
    assert_raises(Schema::ValidationError, 'Failed def validation') do
      TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:type => TestCustomType} })
    end

    assert_raises(Schema::ValidationError, 'Failed def validation') do
      TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:type => TestCustomType, :test => 'fail'} })
    end

    TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:type => TestCustomType, :test => 'valid'} })
  end

  def test_custom_field_value_validation
    TestHelpers.create_schema_with_fields(@test_class, { 'custom' => {:type => TestCustomType, :test => 'valid'} })
    instance_fail = @test_class.new({'custom' => 'fail'})
    assert_raises(Schema::ValidationError, 'Failed value validation') do
      instance_fail.validate
    end
  end

end