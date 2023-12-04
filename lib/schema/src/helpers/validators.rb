module Validators

  def self.required(field, value)
    # If the field is required and it is present, it passes
    return if !field.required
    if (value.nil? || (value.respond_to?(:empty?) && value.empty?))
      raise Schema::ValidationError, "'#{field.key}' is a required field and wasn't found"
    end
  end

  def self.type(field, value)
    return if general_type_check(field.type, value)
    return if field.type_ref && value.is_a?(String) && type_ref_exists(field, value)
    # If it isn't nil or match a standard type or custom type, raise an error
    raise Schema::ValidationError, "'#{field.key}' is expecting type '#{field.type}' but found '#{value.class.to_s}'"
  end

  def self.subtype(field, value)
    return if field.subtype.nil?
    if value.respond_to?(:has_key?)
      value.each { |k,v| subtype_collection_value_check(field, v, k) }
    elsif value.respond_to?(:each)
      value.each { |v| subtype_collection_value_check(field, v) }
    else
      return if general_type_check(field.subtype, value)
      return if field.type_ref && value.is_a?(String) && type_ref_exists(field, value)
      # If it isn't nil or match a standard type or custom type, raise an error
      raise Schema::ValidationError, "'#{field.key}' is expecting type '#{field.subtype}' but found '#{value.class.to_s}'"
    end
  end

  def self.type_ref_exists(field, value)
    return true if !field.type_ref
    type = field.subtype.nil? ? field.type : field.subtype
    value_id = value.is_a?(String) ? value : value.id
    return true if type.respond_to?(:exist?) && type.exist?(value_id)
    raise Schema::ValidationError, "'#{field.key}' is expecting an object or id matching the type ref of type with an existing id '#{type}' but found '#{value.class.to_s}':'#{value_id}'"
  end

  ###################################################################
  #                       HELPER METHODS                            #
  ###################################################################

  private

  def self.general_type_check(type, value)
    # If the type or value is nil or the value matches, it passes
    return true if type.nil? || value.nil? || value.is_a?(type)
    # If it's not a regular type, check if it's a custom type
    return true if type.respond_to?(:type_match?) && type.type_match?(value)
    return false
  end

  def self.subtype_collection_value_check(field, value, hash_key = nil)
    return if general_type_check(field.subtype, value)
    return if type_ref_exists(field, value)
    message = "'#{field.key}' is expecting a collection containing "
    message += "type refs of ids or objects for " if field.type_ref
    message += "'#{field.subtype}' types but found '#{value.class.to_s}'"
    message += " at '#{hash_key}'" if !hash_key.nil?
    raise Schema::ValidationError, message
  end

end