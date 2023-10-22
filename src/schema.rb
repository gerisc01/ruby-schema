require_relative './field_types'
require_relative './field'
require_relative './errors'

## Once schema is loaded, this lets us check on all classes whether an object
## is a schema class or not. For schema classes, this will be true.
class Object
  def is_schema_class?
    return false
  end
end

class Schema

  attr_accessor :key, :display_name, :fields

  def initialize
    @fields = []
  end

  def apply_schema(clazz)
    schema_self = self
    convert_fields_to_field_classes()
    BaseFields.apply(clazz, schema_self)
    TopLevelFields.apply(clazz, schema_self)
    ArrayFields.apply(clazz, schema_self)
    HashFields.apply(clazz, schema_self)
  end

  def validate(instance)
    @fields.each do |field|
      begin
        v = instance.public_send(field.key)
        field.validate(v)
      rescue Schema::ValidationError => e
        raise Schema::ValidationError, "Invalid #{@display_name || @key}: #{e.message}"
      end
    end
  end

  def convert_fields_to_field_classes
    converted_fields = []
    @fields.each do |key, field_def|
      ## If the fields are passed in the format of [{key: field, ...}, {key: field2, ...}],
      #  first convert it to a standard {field1: {...}, field2: {...}} format
      if key.is_a?(Hash)
        field_def = key
        key = field_def['key'] || field_def[:key]
      end
      # Convert fields from a hash of properties to a field object
      converted_fields.push(!key.is_a?(Field) ? Field.from_object(key, field_def) : key)
    end
    @fields = converted_fields
  end

end