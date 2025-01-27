require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../src/storage/schema_type_storage'

class SchemaTypeStorageTest < Minitest::Test

  def setup
    @item1 = {'id' => '1', 'name' => 'One', 'key' => 'one'}
    @item2 = {'id' => '2', 'name' => 'Two', 'key' => 'two'}
    @test_path = 'test_data'

    @storage = SchemaTypeStorage.new(@test_path)
  end

  def teardown
    if Dir.exist?(@test_path)
      FileUtils.remove_dir(@test_path)
    end
  end

  def test_save_and_retrieve_success
    missing_item = @storage.get('test', @item1['id'])
    assert_nil missing_item
    @storage.save('test', @item1['id'], @item1)
    saved_item = @storage.get('test', @item1['id'])
    assert_equal @item1, saved_item
  end

  def test_delete_success
    @storage.save('test', @item1['id'], @item1)
    saved_item = @storage.get('test', @item1['id'])
    assert_equal @item1, saved_item
    @storage.delete('test', @item1['id'])
    missing_item = @storage.get('test', @item1['id'])
    assert_nil missing_item
  end

  def test_list_success
    assert_nil @storage.get('test',@item1['id'])
    assert_nil @storage.get('test',@item2['id'])
    @storage.save('test', @item1['id'], @item1)
    @storage.save('test', @item2['id'],@item2)
    assert_equal [@item1, @item2], @storage.list('test')
  end

  def test_list_include_deleted_success
    assert_nil @storage.get('test',@item1['id'])
    assert_nil @storage.get('test',@item2['id'])
    @storage.save('test', @item1['id'], @item1)
    @storage.save('test', @item2['id'],@item2)
    @storage.delete('test', @item1['id'])
    assert_equal [@item1, @item2], @storage.list('test', {include_deleted: true})
    assert_equal [@item2], @storage.list('test', {})
  end

end