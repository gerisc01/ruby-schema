require_relative '../field'
require_relative '../helpers/field_helpers'
require_relative '../helpers/type_ref'

module HashFields

  def self.apply(clazz, schema)
    hash_fields = schema.fields.select { |field| Hash == field.type }
    hash_fields.each do |field|
      create_add_method(clazz, field)
      create_remove_method(clazz, field)
    end
  end

  def self.create_add_method(clazz, field)
    singular_key = FieldHelpers.singular_field_key(field.key)
    clazz.define_method("upsert_#{singular_key}".to_sym) do |key, value|
      # Validation and type ref processing
      field.validate_subtype(value)
      value = TypeRef.process_type_ref(value, field.subtype) if field.type_ref
      # Add value to hash
      self.json = {} if self.json.nil?
      self.json[field.key] = {} if self.json[field.key].nil?
      self.json[field.key] = self.json[field.key].merge(FieldHelpers.field_type_to_generic(field, {key => value}))
    end
  end

  def self.create_remove_method(clazz, field)
    singular_key = FieldHelpers.singular_field_key(field.key)
    clazz.define_method("remove_#{singular_key}".to_sym) do |key|
      return if self.json.nil? || self.json[field.key].nil? || self.json[field.key].empty?
      # Remove value from hash. Validation and type ref processing not needed
      # here because the key will always be a string.
      self.json[field.key].delete(key)
    end
  end

end