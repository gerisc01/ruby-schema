A schema library for Ruby that allows you to quickly build up classes with a defined schema. This project was
created to helps streamline validation, accessors, and other things that I was doing over and over again while
building out API services.

# Schema: Samples of how to use

## Basic Samples

### Defining and applying the schema
```ruby
class BasicClass
  schema = Schema.new
  schema.key = "numbers"
  schema.display_name = "Number Aggregation"
  schema.fields = {
    "name" => {:required => false, :type => String, :display_name => 'Name'},
    "numbers" => {:required => false, :type => Array, :subtype => Integer, :display_name => 'Numbers'},
    "squares_table" => {:required => false, :type => Hash, :subtype => Integer, :display_name => 'Squares Table'}
  }
  apply_schema schema
end
```

### Create instance with no inputs
```ruby
instance = BasicClass.new
puts "#{instance.id}"
##stdout 963a342f-355c-40d3-a2fd-85a796596151
```

### Create instance with pre-defined values
```ruby
input = {
  'id' => '15',
  'name' => 'A sample name'
}
instance = BasicClass.new(input)
puts "#{instance.id}"
##stdout 15
puts "#{instance.name}"
##stdout A sample name
```

### Using schema methods to access and update instance fields
```ruby
instance = BasicClass.new
instance.id = '12'
instance.name = 'A Name'
instance.add_number(2)
instance.upsert_squares_table('2', 4)
puts "#{instance.to_object}"
##stdout {'id' => '12', 'name' => 'A Name', numbers: [2], squares_table: {'2' => 4}}
```

## Other Use Cases
### Validation
```ruby
class RequiredSample
  schema = Schema.new
  schema.key = "required_sample"
  schema.display_name = "Required Sample"
  schema.fields = {
    "name" => {:required => true, :type => String},
    "num" => {:required => true, :type => Array, :subtype => Integer}
  }
  apply_schema schema
end

# Top Level fields will error out on validate call
instance = RequiredSample.new
instance.validate
## Error thrown because name nor num are present!
instance.add_num("2")
## Error thrown because the input doesn't match the subtype type!
instance.name = 15
instance.validate
# ## Error thrown because name is the wrong type!
instance.name = 'A name'
instance.add_num(2)
instance.validate
## No errors thrown!
```

### Type Ref
```ruby
class TypeRefSample
  schema = Schema.new
  schema.key = "typeref_sample"
  schema.display_name = "Type Ref Sample"
  schema.fields = {
    "item" => {:required => false, :type => Item, :type_ref => true},
    "items" => {:required => false, :type => Array, :subtype => Item, :type_ref => true}
  }
  apply_schema schema
end

instance = TypeRefSample.new
existing_item = Item.new({'id' => '123', 'name' => 'Existing Item'})
instance.item = value
# Item.exist?('123') is called. Because it returns true for this item...
# the item is just transformed down to it's id after being set
instance.to_object
##stdout {'id' => '1', 'item' => '123'}

new_item = Item.new({'id' => '456', 'name' => 'New Item'})
instance.item = new_item
# Item.exist?('456') is called. Because it returns false for this item...
# new_item.save! is called...
# the item is just transformed down to it's id after being set
instance.to_object
##stdout {'id' => '1', 'item' => '456'}

instance.item = '789'
# Item.exist?('789') is called. Because it returns true for this item...
# nothing is changed because the value is already just the reference to the item's id
instance.to_object
##stdout {'id' => '1', 'item' => '789'}

existing_array_item = Item.new({'id' => 'abc', 'name' => 'Existing Item'})
new_array_item = Item.new({'id' => 'def', 'name' => 'New Item'})
existing_array_item_id = 'ghi'
instance.add_item(existing_array_item)
instance.add_item(new_array_item)
instance.add_item(existing_array_item_id)
# The same principles apply to collection fields as well!
```

# Schema Storage: Samples of how to use
Currently, the schema storage portion of the library is a way to store and retrieve
these schema objects. The storage is currently built on top of a file system with a
local cache, but it was built with the intention of being able to be swapped for a
json database and an external cache in the future.

The accessors are applied to each of the schema objects. `:get`, `:list`, and `:exist?`
are used as class methods (e.g. `BasicSchemaClass.get('anId')` or `BasicSchemaClass.list()`).
While `:save!` and `:delete!` are used as instance methods (e.g. `instance.save!` or `instance.delete!`).

## Basic Samples

### Defining and applying the schema
```ruby
storage = SchemaStorage.new('data')
class BasicSchemaClass
  schema = Schema.new
  schema.key = "basic-schema"
  schema.display_name = "Basic Schema"
  schema.storage = storage
  schema.accessors = [:get, :list, :exist?, :save!, :delete!]
  schema.fields = {
    "name" => {:required => false, :type => String, :display_name => 'Name'},
    "key" => {:required => false, :type => String, :display_name => 'Key'}
  }
  apply_schema schema
end
```


# Build and Install
```bash
gem build schema.gemspec
// Install whatever the current version is
gem install schema-0.1.1.gem
```