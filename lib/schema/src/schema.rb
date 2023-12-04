require_relative './field_types'
require_relative './field'
require_relative './errors'
require_relative './custom_types'

class Object
  def is_schema_class?
    false
  end

  def apply_schema(schema)
    schema.apply(self)
  end
end

class Schema

  attr_accessor :key, :display_name, :fields

  def initialize
    @fields = []
  end

  def apply(clazz)
    schema_self = self
    convert_fields_to_field_classes
    BaseFields.apply(clazz, schema_self)
    TopLevelFields.apply(clazz, schema_self)
    ArrayFields.apply(clazz, schema_self)
    HashFields.apply(clazz, schema_self)
  end

  def validate(instance)
    @fields.each do |field|
      begin
        if instance.respond_to?(field.key)
          v = instance.public_send(field.key)
        else
          # To validate a field that doesn't have an accessor, we'll check
          # if the value is stored as a top level field in the json
          v = TopLevelFields.get_field_from_object(field, instance)
        end
        v = instance.public_send(field.key) if instance.respond_to?(field.key)
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