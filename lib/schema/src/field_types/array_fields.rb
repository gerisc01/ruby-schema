require 'set'
require_relative '../field'
require_relative '../helpers/field_helpers'
require_relative '../helpers/type_ref'

module ArrayFields

  def self.apply(clazz, schema)
    array_fields = schema.fields.select { |field| [Array, Set].include?(field.type) }
    array_fields.each do |field|
      create_add_method(clazz, field)
      create_remove_method(clazz, field)
    end
  end

  def self.create_add_method(clazz, field)
    singular_key = FieldHelpers.singular_field_key(field.key)
    clazz.define_method("add_#{singular_key}".to_sym) do |value|
      # Validation and type ref processing
      field.validate_subtype(value)
      value = TypeRef.process_type_ref(value, field.subtype) if field.type_ref
      # Add value to array
      self.json = {} if self.json.nil?
      self.json[field.key] = [] if self.json[field.key].nil?
      self.json[field.key] += FieldHelpers.field_type_to_generic(field, [value])
    end
  end

  def self.create_remove_method(clazz, field)
    singular_key = FieldHelpers.singular_field_key(field.key)
    clazz.define_method("remove_#{singular_key}".to_sym) do |value|
      return if self.json.nil? || self.json[field.key].nil? || self.json[field.key].empty?
      # Validation and type ref processing. Type ref processing is here
      # so that an item can be removed by either an id or it's reference.
      field.validate_subtype(value)
      value = TypeRef.process_type_ref(value, field.subtype) if field.type_ref
      # Remove value from array
      self.json[field.key].delete(value)
    end
  end

end