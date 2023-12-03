require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../../schema/src/schema'
require_relative '../../../schema_storage/src/schema'
require_relative '../../../schema_storage/src/storage/schema_type_storage'

class NoStorageSchema
  schema = Schema.new
  schema.key = "no-storage-schema"
  schema.display_name = "No Schema Storage"
  schema.fields = {
    "name" => {:required => false, :type => String, :display_name => 'Name'},
    "key" => {:required => false, :type => String, :display_name => 'Key'}
  }
  apply_schema schema
end

class CrudMethodsTest < Minitest::Test

  def setup
    @item1 = {'id' => '1', 'name' => 'One', 'key' => 'one'}
  end

  def teardown
  end

  def test_non_storage_schema
    # Confirm no errors are raised when instantiating a schema without a storage
    item = NoStorageSchema.new(@item1)
    assert !item.nil?
  end

end