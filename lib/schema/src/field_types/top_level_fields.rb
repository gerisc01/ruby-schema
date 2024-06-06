require_relative '../field'

module TopLevelFields

  def self.apply(clazz, schema)
    add_id_fields(clazz)
    schema.fields.each do |field|
      field_getter(clazz, field)
      field_setter(clazz, field)
    end
  end

  def self.add_id_fields(clazz)
    id_field = Field.from_schema_object('id', {:required => true, :type => String})
    field_getter(clazz, id_field)
    field_setter(clazz, id_field)
  end

  def self.field_getter(clazz, field)
    clazz.define_method(field.key.to_sym) do
      return TopLevelFields.get_field_from_object(field,self)
    end
  end

  def self.field_setter(clazz, field)
    clazz.define_method("#{field.key}=".to_sym) do |value|
      # Validation and type ref processing
      field.validate(value)
      if field.type_ref && !value.nil?
        if field.subtype.nil?
          value = TypeRef.process_type_ref(value, field.type)
        else
          # TODO: I think this would be broken for hash types
          value = value.map { |v| TypeRef.process_type_ref(v, field.subtype) }
        end
      end
      # Set value
      self.json = {} if json.nil?
      self.json[field.key] = FieldHelpers.field_type_to_generic(field, value)
    end
  end

  def self.get_field_from_object(field, obj)
    json = obj.json.nil? ? {} : obj.json
    value = FieldHelpers.generic_to_field_type(field, json[field.key])
    return value
  end

end