require_relative '../../src/schema'

class TestRef

  attr_accessor :id

  def initialize(json)
    @id = json['id']
  end

end

class BasicSchemaClass
  @@schema = Schema.new
  @@schema.key = "numbers"
  @@schema.display_name = "Number Aggregation"
  @@schema.fields = {
    "name" => {:required => false, :type => String, :display_name => 'Name'},
    "numbers" => {:required => false, :type => Array, :subtype => Integer, :display_name => 'Numbers'},
    "squares_table" => {:required => false, :type => Hash, :subtype => Integer, :display_name => 'Squares Table'}
  }
  @@schema.apply_schema(self)
end

class RequiredSchemaClass
  @@schema = Schema.new
  @@schema.key = "required_sample"
  @@schema.display_name = "Required Sample"
  @@schema.fields = {
    "name" => {:required => true, :type => String},
    "num" => {:required => true, :type => Array, :subtype => Integer}
  }
  @@schema.apply_schema(self)
end

class TypeRefSchemaClass
  @@schema = Schema.new
  @@schema.key = "typeref_sample"
  @@schema.display_name = "Type Ref Sample"
  @@schema.fields = {
    "item" => {:required => false, :type => TestRef, :type_ref => true},
    "items" => {:required => false, :type => Array, :subtype => TestRef, :type_ref => true}
  }
  @@schema.apply_schema(self)
end