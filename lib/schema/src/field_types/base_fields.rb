require 'securerandom'

module BaseFields

  def self.apply(clazz, schema)
    schema_ref(clazz, schema)
    clazz.attr_accessor :json
    init(clazz)
    validate(clazz)
    from_object(clazz)
    to_object(clazz)
    merge(clazz)
    def_equals(clazz)
  end
  
  def self.schema_ref(clazz, schema_self)
    clazz.define_singleton_method(:is_schema_class?) do
      return true
    end
  
    clazz.define_singleton_method(:schema) do
      return schema_self
    end
  end
  
  def self.init(clazz)
    clazz.define_method(:initialize) do |input = nil|
      self.json = input.nil? ? {} : input
      self.json["id"] = SecureRandom.uuid if json["id"].nil?
    end
  end
  
  def self.validate(clazz)
    clazz.define_method(:validate) do
      self.class.schema.validate(self)
    end
  end
  
  def self.from_object(clazz)
    clazz.define_singleton_method(:from_object) do |input|
      return self.new(input)
    end
  end
  
  def self.to_object(clazz)
    clazz.define_method(:to_object) do
      return self.json
    end
  end
  
  def self.merge(clazz)
    clazz.define_method(:merge!) do |input|
      self.json = self.json.merge(input)
    end
  end

  def self.def_equals(clazz)
    clazz.define_method(:==) do |input|
      return false if clazz != input.class
      return self.json == input.json
    end
  end

end