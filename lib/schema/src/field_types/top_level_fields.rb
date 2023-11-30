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
    id_field = Field.from_object('id', {:required => true, :type => String})
    field_getter(clazz, id_field)
    field_setter(clazz, id_field)
  end

  def self.field_getter(clazz, field)
    clazz.define_method(field.key.to_sym) do
      self.json = {} if json.nil?
      value = FieldHelpers.generic_to_field_type(field, self.json[field.key])
      return value
    end
  end

  def self.field_setter(clazz, field)
    clazz.define_method("#{field.key}=".to_sym) do |value|
      # Validation and type ref processing
      field.validate(value)
      if field.type_ref
        if field.subtype.nil?
          value = TypeRef.process_type_ref(value, field.type)
        else
          value = value.map { |v| TypeRef.process_type_ref(v, field.subtype) }
        end
      end
      # Set value
      self.json = {} if json.nil?
      self.json[field.key] = FieldHelpers.field_type_to_generic(field, value)
    end
  end

end