require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative './tegration_setup.rb'

class IntegrationTest < Minitest::Test

  def setup
    @ref_json_new = {'id' => 'new_id'}
    @ref_new = TestRef.new({'id' => 'new_id'})
    @ref_existing = TestRef.new({'id' => 'existing_id'})
    TestRef.stubs(:exist?).with('existing_id').returns(true)
    TestRef.stubs(:exist?).with('new_id').returns(false)
    # Stub so that the same object is returned for easier testing
    TestRef.stubs(:new).with(@ref_json_new).returns(@ref_new)
  end

  def teardown
  end

  def test_no_inputs
    instance = BasicSchemaClass.new
    assert !instance.id.nil?
    instance.validate
  end

  def test_input_values
    input = {
      'id' => '12',
      'name' => 'Test1',
      'numbers' => [2],
      'squares_table' => {'2' => 4}
    }
    instance = BasicSchemaClass.new(input)
    assert_equal '12', instance.id
    assert_equal 'Test1', instance.name
    assert_equal [2], instance.numbers
    assert_equal input['squares_table'] , instance.squares_table
    assert_equal input, instance.to_object
  end

  def test_required
    instance = RequiredSchemaClass.new
    assert_raises(Schema::ValidationError) do
      instance.validate
    end
    instance.name = 'A Name'
    instance.add_num(2)
    instance.validate
  end

  def test_setter_validations
    instance = RequiredSchemaClass.new
    assert_raises(Schema::ValidationError) do
      instance.name = 12
    end
    instance.name = 'A Name'
    assert_raises(Schema::ValidationError) do
      instance.add_num('12')
    end
    instance.add_num(2)
  end

  def test_typeref_setter_object_new
    # Top level field with a new ref
    @ref_new.expects(:save!).times(3)
    instance = TypeRefSchemaClass.new
    instance.item = @ref_new
    assert_equal 'new_id', instance.item
    # Collection field with a ref instance
    instance.add_item(@ref_new)
    assert_equal ['new_id'], instance.items
    # Collection field with a ref instance
    instance.items = [@ref_new]
    assert_equal ['new_id'], instance.items
  end

  def test_typeref_setter_object_existing
    # Top level field with a ref
    instance = TypeRefSchemaClass.new
    instance.item = @ref_existing
    assert_equal 'existing_id', instance.item
    # Collection field with a ref
    instance.add_item(@ref_existing)
    assert_equal ['existing_id'], instance.items
    instance.items = [@ref_existing]
    assert_equal ['existing_id'], instance.items
  end

  def test_typeref_setter_id
    instance = TypeRefSchemaClass.new
    instance.item = @ref_existing.id
    assert_equal 'existing_id', instance.item
    instance.add_item(@ref_existing.id)
    assert_equal ['existing_id'], instance.items
  end

  def test_typeref_invalid
    instance = TypeRefSchemaClass.new
    assert_raises(Schema::ValidationError) do
      instance.item = 'new_id'
    end
    assert_raises(Schema::ValidationError) do
      instance.item = 123
    end
  end

end