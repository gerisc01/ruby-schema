class SchemaType

  class Boolean

    def self.type_match?(value)
      return value.is_a?(TrueClass) || value.is_a?(FalseClass)
    end

  end

end