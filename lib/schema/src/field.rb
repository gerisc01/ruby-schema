require_relative './helpers/validators'

class Field

  attr_accessor :key, :display_name, :type, :subtype, :required, :type_ref, :extra_attrs

  def validate(value)
    Validators.required(self, value)
    Validators.type(self, value)
    Validators.subtype(self, value)
    Validators.field_value_validation(self, value)
  end

  def validate_subtype(value)
    Validators.subtype(self, value)
  end

  def validate_type_ref_exists(value)
    Validators.type_ref_exists(self, value)
  end

  def validate_def
    raise Schema::ValidationError.new("Field key must be a non-empty string") if key.nil? || key.empty? || !key.is_a?(String)
    raise Schema::ValidationError.new("Field required must be a boolean") unless required.is_a?(TrueClass) || required.is_a?(FalseClass) || required.nil?
    raise Schema::ValidationError.new("Field type_ref must be a boolean") unless type_ref.is_a?(TrueClass) || type_ref.is_a?(FalseClass) || type_ref.nil?
    raise Schema::ValidationError.new("Field type must be a class") unless type.is_a?(Class) || type.nil?
    raise Schema::ValidationError.new("Field subtype must be a class") unless subtype.is_a?(Class) || subtype.nil?
    raise Schema::ValidationError.new("Field extra_attrs must be a hash") unless extra_attrs.is_a?(Hash) || extra_attrs.nil?
    field_type = subtype.nil? ? type : subtype
    field_type.field_def_validation(self) if field_type.respond_to?(:field_def_validation)
  end

  def to_schema_object
    result = {
      'key' => key,
      'display_name' => display_name,
      'type' => type,
      'subtype' => subtype,
      'required' => required,
      'type_ref' => type_ref
    }
    result.merge!(extra_attrs) if extra_attrs
    result
  end

  def self.from_schema_object(key, obj = nil)
    if obj.nil?
      obj = key
      key = obj['key'] || obj[:key]
    end
    field = Field.new
    field.key = key
    field.display_name = obj['display_name'] || obj[:display_name]
    field.type = Field.from_type(obj, 'type')
    field.subtype = Field.from_type(obj, 'subtype')
    field.required = Field.from_boolean(obj, 'required')
    field.type_ref = Field.from_boolean(obj, 'type_ref')
    field.extra_attrs = obj.reject { |k, v| ['key', 'display_name', 'type', 'subtype', 'required', 'type_ref'].include?(k.to_s) }
    field.validate_def
    return field
  end

  ###################################################################
  #                       HELPER METHODS                            #
  ###################################################################

  private

  def self.from_type(obj, field_name)
    value = obj[field_name] || obj[field_name.to_sym]
    value = Module.const_get(value) if value.is_a?(String)
    return value
  end

  def self.from_boolean(obj, field_name)
    value = obj[field_name] || obj[field_name.to_sym]
    value = false if value.nil? && (obj[field_name] == false || obj[field_name.to_sym] == false)
    return value
  end
  
end