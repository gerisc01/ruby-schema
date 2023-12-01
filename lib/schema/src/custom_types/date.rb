require 'date'

class SchemaType
  class Date

    def self.type_match?(value)
      begin
        return value.is_a?(::Date) || ::Date.parse(value)
      rescue
        return false
      end
    end

  end
end