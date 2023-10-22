module TestHelpers

  def self.create_schema_with_fields(clazz, fields)
    schema = Schema.new
    schema.fields = fields
    schema.apply_schema(clazz)
  end

end