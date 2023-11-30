require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../../ruby-schema'
require_relative '../../../ruby-schema-storage'

module TestVars
  def self.path
    'test_data'
  end
  def self.storage
    SchemaTypeStorage.new(path)
  end
end

class BasicSchemaClass
  schema = Schema.new
  schema.key = "basic-schema"
  schema.display_name = "Basic Schema"
  schema.storage = TestVars.storage
  schema.accessors = [:get, :list, :exist?, :save!, :delete!]
  schema.fields = {
    "name" => {:required => false, :type => String, :display_name => 'Name'},
    "key" => {:required => false, :type => String, :display_name => 'Key'}
  }
  apply_schema schema
end

class SchemaAccessorsTest < Minitest::Test

  def setup
    @item1 = {'id' => '1', 'name' => 'One', 'key' => 'one'}
    @item2 = {'id' => '2', 'name' => 'Two', 'key' => 'two'}

    @storage = SchemaTypeStorage.new(TestVars.path)
  end

  def teardown
    if Dir.exist?(TestVars.path)
      FileUtils.remove_dir(TestVars.path)
    end
    BasicSchemaClass.schema.storage.clear_cache
  end

  def test_save_and_retrieve
    item = BasicSchemaClass.new(@item1)
    item.save!
    BasicSchemaClass.schema.storage.clear_cache
    saved_item = BasicSchemaClass.get(@item1['id'])
    assert_equal item, saved_item
    uncreated_item = BasicSchemaClass.get(@item2['id'])
    assert_nil uncreated_item
  end

  def test_save_and_exist
    item = BasicSchemaClass.new(@item1)
    item.save!
    BasicSchemaClass.schema.storage.clear_cache
    assert BasicSchemaClass.exist?(@item1['id'])
    assert !BasicSchemaClass.exist?(@item2['id'])
  end

  def test_save_and_list_and_delete
    assert_equal [], BasicSchemaClass.list
    item1 = BasicSchemaClass.new(@item1)
    item1.save!
    item2 = BasicSchemaClass.new(@item2)
    item2.save!
    BasicSchemaClass.schema.storage.clear_cache
    assert_equal [item1, item2], BasicSchemaClass.list
    item1.delete!
    assert_equal [item2], BasicSchemaClass.list
  end

end