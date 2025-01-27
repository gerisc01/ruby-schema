require_relative '../errors'

module CrudMethods

  def self.apply(clazz, storage, methods)
    return if methods.nil?
    methods.each do |method|
      case method
      when :get
        get(clazz, storage)
      when :exist?
        exist?(clazz, storage)
      when :list
        list(clazz, storage)
      when :save!
        save!(clazz, storage)
      when :delete!
        delete!(clazz, storage)
      else
        raise Schema::ValidationError, "Invalid method: #{method}"
      end
    end
  end

  def self.get(clazz, storage)
    clazz.define_singleton_method(:get) do |id, opts = {}|
      json = storage.get(CrudMethods.get_table(clazz), id, opts)
      clazz.new(json) unless json.nil?
    end
  end

  def self.exist?(clazz, storage)
    clazz.define_singleton_method(:exist?) do |id|
      storage.get(CrudMethods.get_table(clazz), id) != nil
    end
  end

  def self.list(clazz, storage)
    clazz.define_singleton_method(:list) do |opts = {}|
      json_list = storage.list(CrudMethods.get_table(clazz), opts)
      json_list.map { |json| clazz.new(json) }
    end
  end

  def self.save!(clazz, storage)
    clazz.define_method(:save!) do
      self.validate
      storage.save(CrudMethods.get_table(self), CrudMethods.get_id(self), self.json)
    end
  end

  def self.delete!(clazz, storage)
    clazz.define_method(:delete!) do
      raise Schema::ValidationError, "Invalid #{self.class.to_s}: id cannot be nil" if self.json['id'].to_s.empty?
      storage.delete(CrudMethods.get_table(self), CrudMethods.get_id(self))
    end
  end

  private

  def self.get_table(obj)
    obj.is_a?(Class) ? obj.schema.key : obj.class.schema.key
  end

  def self.get_id(obj)
    obj.json['id']
  end

end