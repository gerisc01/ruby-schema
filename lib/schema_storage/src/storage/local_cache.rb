class LocalCache

  attr_accessor :cache

  def initialize
    @cache = {}
  end

  def get(table, key = nil)
    if table != nil && key != nil
      return nil if @cache[table].nil?
      @cache[table][key]
    elsif table != nil
      return {} if @cache[table].nil?
      @cache[table]
    end
  end

  def insert(table, key, value)
    @cache[table] = {} if @cache[table].nil?
    @cache[table][key] = value
  end

  def exist?(table, key = nil)
    key.nil? ? !@cache[table].nil? : @cache[table][key].nil?
  end

  def clear(table = nil, key = nil)
    if table != nil && key != nil
      @cache[table].delete(key)
    elsif table != nil
      @cache.delete(table)
    else
      @cache = {}
    end
  end

end