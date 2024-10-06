require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../../schema/src/schema'
require_relative '../../../schema_storage/src/schema'
require_relative '../../../schema_storage/src/storage/schema_type_storage'

require 'time'

class SchemaTypeStorageUnitTest < Minitest::Test

  def setup
    @item1 = {'id' => '1', 'name' => 'One', 'key' => 'one'}
    @item2 = {'id' => '2', 'name' => 'Two', 'key' => 'two'}
  end

  def teardown
  end

  def test_save_all_ids_no_duplicates
    mock_local_db('test', {'1' => @item1})
    storage = SchemaTypeStorage.new('unit_test')

    assert_equal ['1'], storage.get('test', 'all_ids')
    storage.save('test', @item1['id'], @item1)
    storage.save('test', @item2['id'], @item2)
    assert_equal ['1', '2'], storage.get('test', 'all_ids')
  end

  def test_save_updated_at
    Time.stubs(:now).returns(Time.utc(2024, 10, 5, 12, 35))

    mock_local_db('items', {})
    storage = SchemaTypeStorage.new('unit_test')
    storage.save('items', '1', @item1)

    assert_equal Time.utc(2024, 10, 5, 12, 35).iso8601, @item1['updated_at']
  end

  def test_list_no_since
    items = {
      '1' => {'id' => '1', 'name' => 'One', 'key' => 'one', 'updated_at' => Time.utc(2024,10, 2, 12, 35).iso8601},
      '2' => {'id' => '2', 'name' => 'Two', 'key' => 'two', 'updated_at' => Time.utc(2024, 10, 5, 12, 35).iso8601}
    }
    mock_local_db('items', items)

    storage = SchemaTypeStorage.new('unit_test')
    items = storage.list('items')
    assert_equal 2, items.length
  end

  def test_list_since_date_after
    items = {
      '1' => {'id' => '1', 'name' => 'One', 'key' => 'one', 'updated_at' => Time.utc(2024,10, 2, 12, 35).iso8601},
      '2' => {'id' => '2', 'name' => 'Two', 'key' => 'two', 'updated_at' => Time.utc(2024, 10, 5, 12, 35).iso8601}
    }
    mock_local_db('items', items)

    storage = SchemaTypeStorage.new('unit_test')
    items = storage.list('items', '2024-10-06T12:35:00Z')
    assert_equal 0, items.length
  end

  def test_list_since_date_before
    items = {
      '1' => {'id' => '1', 'name' => 'One', 'key' => 'one', 'updated_at' => Time.utc(2024,10, 2, 12, 35).iso8601},
      '2' => {'id' => '2', 'name' => 'Two', 'key' => 'two', 'updated_at' => Time.utc(2024, 10, 5, 12, 35).iso8601}
    }
    mock_local_db('items', items)

    storage = SchemaTypeStorage.new('unit_test')
    items = storage.list('items', '2024-10-01T12:35:00Z')
    assert_equal 2, items.length
  end

  def test_list_since_date_between
    items = {
      '1' => {'id' => '1', 'name' => 'One', 'key' => 'one', 'updated_at' => Time.utc(2024,10, 2, 12, 35).iso8601},
      '2' => {'id' => '2', 'name' => 'Two', 'key' => 'two', 'updated_at' => Time.utc(2024, 10, 5, 12, 35).iso8601}
    }
    mock_local_db('items', items)

    storage = SchemaTypeStorage.new('unit_test')
    items = storage.list('items', '2024-10-03T12:35:00Z')
    assert_equal 1, items.length
  end

  def test_list_since_no_updated_at
    items = {
      '1' => {'id' => '1', 'name' => 'One', 'key' => 'one', 'updated_at' => Time.utc(2024,10, 2, 12, 35).iso8601},
      '2' => {'id' => '2', 'name' => 'Two', 'key' => 'two'}
    }
    mock_local_db('items', items)

    storage = SchemaTypeStorage.new('unit_test')
    items = storage.list('items', '2024-10-04T12:35:00Z')
    assert_equal 1, items.length
  end

  def test_list_since_no_updated_at_saved_after
    Time.stubs(:now).returns(Time.utc(2024, 10, 5, 12, 35))

    items = {
      '1' => {'id' => '1', 'name' => 'One', 'key' => 'one', 'updated_at' => Time.utc(2024,10, 2, 12, 35).iso8601},
      '2' => {'id' => '2', 'name' => 'Two', 'key' => 'two'}
    }
    mock_local_db('items', items)

    storage = SchemaTypeStorage.new('unit_test')
    items = storage.list('items', '2024-10-04T12:35:00Z')
    assert_equal 1, items.length
    assert_equal Time.utc(2024, 10, 5, 12, 35).iso8601, items[0]['updated_at']
  end

  def mock_local_db(table, data)
    local_db = mock()
    local_db.stubs(:persist)
    local_db.stubs(:load).with(table).returns(data)
    LocalFilesDb.stubs(:new).returns(local_db)
  end

end