require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class BaseFieldsTest < Minitest::Test

  def setup
    @test_class = Class.new
  end

  def teardown
    @test_class = nil
  end

  def test_is_schema_class
    assert !@test_class.is_schema_class?
    TestHelpers.create_schema_with_fields(@test_class, {'test_field' => {:required => true}})
    assert @test_class.is_schema_class?
  end

  def test_get_schema
    fields = {'test_field' => {:required => true}}
    TestHelpers.create_schema_with_fields(@test_class, fields)
    assert @test_class.schema
    assert_equal 'test_field', @test_class.schema.fields[0].key
    assert_equal true, @test_class.schema.fields[0].required
  end

  def test_initialize_empty
    TestHelpers.create_schema_with_fields(@test_class, {'test_field' => {:required => false}})
    instance = @test_class.new
    assert instance
    assert !instance.json['id'].nil?
  end

  def test_initialize_inputs
    TestHelpers.create_schema_with_fields(@test_class, {'test_field' => {:required => false}})
    field_instance = @test_class.new({'test_field' => 'Something'})
    assert field_instance
    assert !field_instance.json['id'].nil?

    id_instance = @test_class.new({'id' => '12345'})
    assert id_instance
    assert_equal '12345', id_instance.json['id']
  end

  def test_validate_called
    TestHelpers.create_schema_with_fields(@test_class, {'test_field' => {:required => false}})
    instance = @test_class.new({'test_field' => 'Something'})
    
    @test_class.schema.stubs(:validate).returns(false).once
    assert !instance.validate

    @test_class.schema.stubs(:validate).returns(true).once
    assert instance.validate
  end

  def test_to_from_schema_object
    TestHelpers.create_schema_with_fields(@test_class, {'test_field' => {:required => false}})
    input = {'id' => '1', 'test_field' => 'Something'}
    instance = @test_class.new(input)
    
    json = instance.to_schema_object
    object = @test_class.from_schema_object(json)

    assert_equal input, json
    assert_equal instance, object
  end

end