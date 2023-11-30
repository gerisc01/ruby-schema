module TestHelpers

  def self.create_schema_with_fields(clazz, fields)
    schema = Schema.new
    schema.fields = fields
    clazz.apply_schema schema
  end

end