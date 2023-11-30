require_relative './helpers/validators'

class Field

  attr_accessor :key, :display_name, :type, :subtype, :required, :type_ref

  def validate(value)
    Validators.required(self, value)
    Validators.type(self, value)
    Validators.subtype(self, value)
  end

  def validate_subtype(value)
    Validators.subtype(self, value)
  end

  def validate_type_ref_exists(value)
    Validators.type_ref_exists(self, value)
  end

  def validate_def
  end

  def to_object
    {
      'key' => key,
      'display_name' => display_name,
      'type' => type,
      'subtype' => subtype,
      'required' => required,
    }
  end

  def self.from_object(key, obj)
    field = Field.new
    field.key = key
    field.display_name = obj['display_name'] || obj[:display_name]
    field.type = Field.from_type(obj, 'type')
    field.subtype = Field.from_type(obj, 'subtype')
    field.required = Field.from_boolean(obj, 'required')
    field.type_ref = Field.from_boolean(obj, 'type_ref')
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