require 'json'
require 'time'
require_relative './local_cache'
require_relative './local_files_db'

class SchemaTypeStorage

  def initialize(file_path = 'data')
    @cache = LocalCache.new
    @db = LocalFilesDb.new(file_path)
  end

  def get(table, id, opts = {})
    load_cache_from_db(table) unless @cache.exist?(table)
    result = @cache.get(table, id)
    if !result.nil? && result.is_a?(Hash)
      result['updated_at'] = Time.now.utc.iso8601 if result['updated_at'].nil?
      unless (since = opts[:since]).nil?
        result = nil if result['updated_at'] < since
      end
      result = nil if include_deleted?(opts) && !result.nil? && result['deleted']
    end
    result
  end

  def list(table, opts = {})
    load_cache_from_db(table) unless @cache.exist?(table)
    objects = @cache.get(table, 'all_ids')
                   .map { |id| @cache.get(table, id) }
    result = []
    if (since = opts[:since]).nil?
      result = objects
    else
      objects.each do |obj|
        obj['updated_at'] = Time.now.utc.iso8601 if obj['updated_at'].nil?
        result << obj if obj['updated_at'] > since
      end
    end

    if include_deleted?(opts)
      result = result.reject { |obj| obj['deleted'] }
    end
    result
  end

  def save(table, id, obj)
    return if obj.nil?

    load_cache_from_db(table) unless @cache.exist?(table)
    obj['updated_at'] = Time.now.utc.iso8601
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
    obj = @cache.get(table, id)
    obj['updated_at'] = Time.now.utc.iso8601
    obj['deleted'] = true
    @cache.insert(table, id, obj)
    persist_without_all_ids(table)
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

  def include_deleted?(opts)
    opts[:include_deleted].nil? || opts[:include_deleted] == false
  end

end