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

class AccessorsSchemaTest
  schema = Schema.new
  schema.key = "accessors-schema-test"
  schema.display_name = "Accessors Schema Test"
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
    AccessorsSchemaTest.schema.storage.clear_cache
  end

  def test_save_and_retrieve
    item = AccessorsSchemaTest.new(@item1)
    item.save!
    AccessorsSchemaTest.schema.storage.clear_cache
    saved_item = AccessorsSchemaTest.get(@item1['id'])
    assert_equal item, saved_item
    uncreated_item = AccessorsSchemaTest.get(@item2['id'])
    assert_nil uncreated_item
  end

  def test_save_and_exist
    item = AccessorsSchemaTest.new(@item1)
    item.save!
    AccessorsSchemaTest.schema.storage.clear_cache
    assert AccessorsSchemaTest.exist?(@item1['id'])
    assert !AccessorsSchemaTest.exist?(@item2['id'])
  end

  def test_save_and_list_and_delete
    assert_equal [], AccessorsSchemaTest.list
    item1 = AccessorsSchemaTest.new(@item1)
    item1.save!
    item2 = AccessorsSchemaTest.new(@item2)
    item2.save!
    AccessorsSchemaTest.schema.storage.clear_cache
    assert_equal [item1, item2], AccessorsSchemaTest.list
    item1.delete!
    assert_equal [item2], AccessorsSchemaTest.list
  end

end