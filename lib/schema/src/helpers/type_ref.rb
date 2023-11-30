module TypeRef

  def self.process_type_ref(value, type_ref)
    raise Schema::ValidationError, "Invalid Type Ref: Expecting '#{type_ref.to_s}' but received '#{value.class.to_s}'" if !(value.is_a?(type_ref) || (type_ref.respond_to?(:type_match?) &&  type_ref.type_match?(value))) && !value.is_a?(String)
    if (value.is_a?(type_ref) || (type_ref.respond_to?(:type_match?) &&  type_ref.type_match?(value)))
      raise Schema::ValidationError, "Invalid Type Ref: Received a type ref instance of type '#{type_ref.to_s}' without an :id method" if !value.respond_to?(:id)
      value.save! if !type_ref.public_send(:exist?, value.id)
      id = value.id
    else
      id = value
      raise Schema::ValidationError, "Invalid Type Ref: Can't add type ref instance with id '#{id}' because an object matching the id doesn't exist" if !type_ref.public_send(:exist?, id)
    end
    return id
  end

  ###################################################################
  #                       HELPER METHODS                            #
  ###################################################################

  private

  def self.validate_initial_type(value, type_ref)
    raise Schema::ValidationError, "Invalid Type Ref: Expecting '#{type_ref.to_s}' but received '#{value.class.to_s}'" if !(value.is_a?(type_ref) || (type_ref.respond_to?(:type_match?) &&  type_ref.type_match?(value))) && !value.is_a?(String)
  end

end