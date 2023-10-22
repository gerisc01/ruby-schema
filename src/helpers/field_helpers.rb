module FieldHelpers

  def self.generic_to_field_type(field, value)
    if field.type.is_schema_class?
      return field.type.new(value)
    else
      return value
    end
  end

  def self.field_type_to_generic(field, value)
    if field.type.is_schema_class?
      return value.to_object
    else
      return value
    end
  end

  def self.singular_field_key(field_key)
    return field_key[-1] == "s" ? field_key[0...-1] : field_key
  end

end