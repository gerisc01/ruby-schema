require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/test'
require_relative '../../src/schema'
require_relative '../helpers/test_helpers'

class NestedSchemasTest < Minitest::Test

  def setup
    @lower_level_ref = Class.new
    TestHelpers.create_schema_with_fields(@lower_level_ref, [
      {:key => 'an_int', :required => true, :type => Integer},
      {:key => 'a_str', :required => true, :type => String}
    ])
    @top_level_ref = Class.new
    TestHelpers.create_schema_with_fields(@top_level_ref, [
      {:key => 'lower_level', :required => true, :type => @lower_level_ref},
    ])

    @test_class = Class.new
    TestHelpers.create_schema_with_fields(@test_class, [
      {:key => 'top_level', :type => @top_level_ref},
      {:key => 'arrays', :type => Array, :subtype => @top_level_ref},
      {:key => 'hashs', :type => Hash, :subtype => @top_level_ref},
    ])
  end

  def teardown
    @lower_level_ref = nil
    @top_level_ref = nil
    @test_class = nil
  end

  def test_nested_getter_top_level
    instance = @test_class.new({'top_level' => {'lower_level' => {'an_int' => 1, 'a_str' => 'a'}}})
    assert instance.top_level.is_a?(@top_level_ref)
    top_level_instance = instance.top_level
    assert top_level_instance.lower_level.is_a?(@lower_level_ref)
    lower_level_instance = top_level_instance.lower_level
    assert_equal 1, lower_level_instance.an_int
    assert_equal 'a', lower_level_instance.a_str
  end

  def test_nested_setter_top_level
    lower_level_instance = @lower_level_ref.new({'id' => '1', 'an_int' => 1, 'a_str' => 'a'})
    top_level_instance = @top_level_ref.new({'id' => '1', 'lower_level' => lower_level_instance})
    instance = @test_class.new({'id' => '1'})
    instance.top_level = top_level_instance
    instance_json = instance.json
    expected_json = {'id' => '1', 'top_level' => {'id' => '1', 'lower_level' => {'id' => '1', 'an_int' => 1, 'a_str' => 'a'}}}
    assert_equal expected_json['top_level'], instance_json['top_level']
  end

  def test_nested_getter_array
    instance = @test_class.new({'arrays' => [
      {'lower_level' => {'an_int' => 1, 'a_str' => 'a'}},
      {'lower_level' => {'an_int' => 2, 'a_str' => 'b'}}
    ]})
    assert instance.arrays[0].is_a?(@top_level_ref)
    assert instance.arrays[1].is_a?(@top_level_ref)
    top_level_instance = instance.arrays[0]
    assert top_level_instance.lower_level.is_a?(@lower_level_ref)
    lower_level_instance = top_level_instance.lower_level
    assert_equal 1, lower_level_instance.an_int
    assert_equal 'a', lower_level_instance.a_str
  end

  def test_nested_setter_array
    lower_level_instance1 = @lower_level_ref.new({'id' => '1', 'an_int' => 1, 'a_str' => 'a'})
    lower_level_instance2 = @lower_level_ref.new({'id' => '2', 'an_int' => 2, 'a_str' => 'b'})
    top_level_instance1 = @top_level_ref.new({'id' => '1', 'lower_level' => lower_level_instance1})
    top_level_instance2 = @top_level_ref.new({'id' => '2', 'lower_level' => lower_level_instance2})
    instance = @test_class.new({'id' => '1'})
    instance.arrays = [top_level_instance1]
    instance.add_array(top_level_instance2)
    instance_json = instance.json
    expected_json = {'id' => '1', 'arrays' => [
      {'id' => '1', 'lower_level' => {'id' => '1', 'an_int' => 1, 'a_str' => 'a'}},
      {'id' => '2', 'lower_level' => {'id' => '2', 'an_int' => 2, 'a_str' => 'b'}}
    ]}
    assert_equal expected_json['arrays'], instance_json['arrays']
  end

  def test_nested_getter_hash
    instance = @test_class.new({'hashs' => {
      '1' => {'lower_level' => {'an_int' => 1, 'a_str' => 'a'}},
      '2' => {'lower_level' => {'an_int' => 2, 'a_str' => 'b'}}
    }})
    assert instance.hashs['1'].is_a?(@top_level_ref)
    assert instance.hashs['2'].is_a?(@top_level_ref)
    top_level_instance = instance.hashs['1']
    assert top_level_instance.lower_level.is_a?(@lower_level_ref)
    lower_level_instance = top_level_instance.lower_level
    assert_equal 1, lower_level_instance.an_int
    assert_equal 'a', lower_level_instance.a_str
  end

  def test_nested_setter_hash
    lower_level_instance1 = @lower_level_ref.new({'id' => '1', 'an_int' => 1, 'a_str' => 'a'})
    lower_level_instance2 = @lower_level_ref.new({'id' => '2', 'an_int' => 2, 'a_str' => 'b'})
    top_level_instance1 = @top_level_ref.new({'id' => '1', 'lower_level' => lower_level_instance1})
    top_level_instance2 = @top_level_ref.new({'id' => '2', 'lower_level' => lower_level_instance2})
    instance = @test_class.new({'id' => '1'})
    instance.hashs = {'1' => top_level_instance1}
    instance.upsert_hash('2', top_level_instance2)
    instance_json = instance.json
    expected_json = {'id' => '1', 'hashs' =>{
      '1' => {'id' => '1', 'lower_level' => {'id' => '1', 'an_int' => 1, 'a_str' => 'a'}},
      '2' => {'id' => '2', 'lower_level' => {'id' => '2', 'an_int' => 2, 'a_str' => 'b'}}
    }}
    assert_equal expected_json, instance_json
  end

end