module FieldHelpers

  def self.generic_to_field_type(field, value)
    if field.subtype.respond_to?(:from_schema_object) && field.type == Hash
      return value.map { |k,v| [k, field.subtype.from_schema_object(v)] }.to_h
    elsif field.type.respond_to?(:from_schema_object) && value.is_a?(Hash)
      return field.type.from_schema_object(value)
    elsif field.subtype.respond_to?(:from_schema_object) && value.respond_to?(:map)
      return value.map { |v| field.subtype.from_schema_object(v) }
    else
      return value
    end
  end

  def self.field_type_to_generic(field, value)
    if value.respond_to?(:to_schema_object) && value.is_a?(field.type)
      return convert_schema_object(field, value)
    elsif field.subtype.respond_to?(:from_schema_object) && value.is_a?(Hash)
      return value.map { |k,v| [k, convert_schema_object(field, v)] }.to_h
    elsif field.subtype.respond_to?(:from_schema_object) && value.respond_to?(:map)
      return value.map { |v| convert_schema_object(field, v) }
    else
      return value
    end
  end

  def self.singular_field_key(field_key)
    return field_key[-1] == "s" ? field_key[0...-1] : field_key
  end

  private

  def self.convert_schema_object(field, value)
    json = value.to_schema_object
    if value.class.is_schema_class?
      value.class.schema.fields.each do |field|
        json[field.key] = FieldHelpers.field_type_to_generic(field, json[field.key])
      end
    end
    return json
  end

end