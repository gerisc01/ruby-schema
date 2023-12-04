require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class TopLevelFieldsTest < Minitest::Test

  def setup
    @test_class = Class.new
    fields = {
      'req' => {:required => true},
      'str' => {:type => String}
    }
    TestHelpers.create_schema_with_fields(@test_class, fields)
  end

  def teardown
    @test_class = nil
  end

  def test_getter
    instance = @test_class.new({'id' => '1', 'req' => 25, 'str' => 'something'})
    assert_equal '1', instance.id
    assert_equal 25, instance.req
    assert_equal 'something', instance.str
  end

  def test_setter
    instance = @test_class.new
    instance.id = '2'
    instance.req = 50
    instance.str = 'something else'

    assert_equal '2', instance.id
    assert_equal 50, instance.req
    assert_equal 'something else', instance.str
  end

  def test_setter_wrong_type
    instance = @test_class.new
    assert_raises(Schema::ValidationError) do
      instance.str = 25
    end
  end

  def test_setter_type_ref
    @top_level_class = Class.new
    TestHelpers.create_schema_with_fields(@top_level_class, {'ref' => {:type => @test_class, :type_ref => true}})
    @test_class.stubs(:exist?).with('1').returns(true)
    top_level_instance = @top_level_class.new
    instance = @test_class.new({'id' => '1', 'req' => 75})
    top_level_instance.ref = instance
    assert_equal instance.id, top_level_instance.ref
  end

end