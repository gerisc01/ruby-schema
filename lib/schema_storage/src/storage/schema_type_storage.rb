require 'json'
require_relative './local_cache'
require_relative './local_files_db'

class SchemaTypeStorage

  def initialize(file_path = 'data')
    @cache = LocalCache.new
    @db = LocalFilesDb.new(file_path)
  end

  def get(table, id)
    load_cache_from_db(table) unless @cache.exist?(table)
    @cache.get(table, id)
  end

  def list(table)
    load_cache_from_db(table) unless @cache.exist?(table)
    @cache.get(table, 'all_ids').map { |id| @cache.get(table, id) }
  end

  def save(table, id, obj)
    load_cache_from_db(table) unless @cache.exist?(table)
    @cache.insert(table, id, obj)
    persist_without_all_ids(table)
    obj_ids = @cache.get(table, 'all_ids')
    unless obj_ids.include?(id)
      obj_ids.push(id)
      @cache.insert(table, 'all_ids', obj_ids)
    end
  end

  def delete(table, id)
    load_cache_from_db(table) unless @cache.exist?(table)
    @cache.clear(table, id)
    persist_without_all_ids(table)
    obj_ids = @cache.get(table, 'all_ids')
    obj_ids.delete(id)
    @cache.insert(table, 'all_ids', obj_ids)
  end

  def clear_cache
    @cache.clear
  end

  private

  def load_cache_from_db(table)
    objs = @db.load(table)
    obj_ids = []
    objs.each do |id, obj|
      @cache.insert(table, id, obj)
      obj_ids << id
    end
    @cache.insert(table, 'all_ids', obj_ids)
  end

  def get_obj_id(obj)
    if obj.is_a?(Hash)
      obj['id']
    elsif obj.respond_to?(:json)
      obj.json['id']
    else
      raise "Failed to load into cache: Can't find an id for #{obj}"
    end
  end

  def persist_without_all_ids(table)
    table_cache = @cache.get(table)
    table_cache = {} if table_cache.nil?
    @db.persist(table, table_cache.reject { |k, v| k == 'all_ids'})
  end

end