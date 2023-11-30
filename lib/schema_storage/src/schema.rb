require_relative './methods/crud_methods'

class Object
  def apply_schema(schema)
    schema.apply(self)
    schema.apply_storage(self)
  end
end

class Schema

  attr_accessor :accessors, :storage

  def apply_storage(clazz)
    raise Schema::ValidationError, "Invalid storage: Storage must be set to apply accessors" if @storage.nil? && !@accessors.nil?
    CrudMethods.apply(clazz, @storage, @accessors)
  end

end