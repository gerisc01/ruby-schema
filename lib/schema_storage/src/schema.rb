require_relative './methods/crud_methods'

class Object

  # Remove the old apply_schema method if it exists
  remove_method :apply_schema if method_defined? :apply_schema

  # Add the new apply_schema method
  def apply_schema(schema)
    schema.apply(self)
    schema.apply_storage(self)
  end
end

class Schema

  attr_accessor :accessors, :storage

  def apply_storage(clazz)
    if (!defined?(@storage) || @storage.nil?) && (defined?(@accessors) && !@accessors.nil?)
      raise Schema::ValidationError, "Invalid storage: Storage must be set to apply accessors"
    end

    if defined?(@storage) && defined?(@accessors)
      CrudMethods.apply(clazz, @storage, @accessors)
    end
  end

end