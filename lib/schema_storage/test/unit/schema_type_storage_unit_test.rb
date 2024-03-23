require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../../schema/src/schema'
require_relative '../../../schema_storage/src/schema'
require_relative '../../../schema_storage/src/storage/schema_type_storage'

class SchemaTypeStorageUnitTest < Minitest::Test

  def setup
    @item1 = {'id' => '1', 'name' => 'One', 'key' => 'one'}
  end

  def teardown
  end

  def test_save_all_ids_no_duplicates
    # Setup the mocks that are needed
    mock_local_files_db = mock()
    mock_local_files_db.stubs(:persist)
    LocalFilesDb.expects(:new).returns(mock_local_files_db)
    cache = mock()
    LocalCache.expects(:new).returns(cache)
    storage = SchemaTypeStorage.new('unit_test')

    cache.stubs(:exist?).with('test').returns(true)
    cache.stubs(:insert).with('test', '1', anything)
    cache.stubs(:get).with('test').returns({})
    cache.stubs(:get).with('test', 'all_ids').returns([@item1['id'], '2'])

    cache.expects(:insert).with('test', 'all_ids', anything).never
    storage.save('test', @item1['id'], @item1)
  end

end