# ruby-schema

A Ruby gem for building classes with a declared schema. Define fields once; get typed accessors, validation, and optional file-backed persistence automatically. Built to eliminate repetitive boilerplate in API services.

---

## Installation

```bash
gem build ruby-schema.gemspec
gem install ruby-schema-0.6.2.gem
```

Or in a Gemfile:

```ruby
gem 'ruby-schema'
```

---

## Quick Start

```ruby
require 'ruby-schema'

class Product
  schema = Schema.new
  schema.key = "product"
  schema.display_name = "Product"
  schema.fields = {
    "name"  => { required: true,  type: String },
    "price" => { required: true,  type: Float },
    "tags"  => { required: false, type: Array, subtype: String }
  }
  apply_schema schema
end

p = Product.new
p.name  = "Widget"
p.price = 9.99
p.add_tag("sale")
p.validate  # raises Schema::ValidationError if invalid
p.to_schema_object
# => {"id" => "...", "name" => "Widget", "price" => 9.99, "tags" => ["sale"]}
```

---

## Core Concepts

### Schema Definition

A `Schema` object holds the configuration for a class. Set it up and call `apply_schema` inside the class body.

```ruby
schema = Schema.new
schema.key          = "my_entity"     # used as storage table name
schema.display_name = "My Entity"     # used in validation error messages
schema.fields       = { ... }
apply_schema schema
```

### Field Options

| Option | Type | Description |
|---|---|---|
| `required` | Boolean | Raises on `validate` if nil or empty |
| `type` | Class | Expected Ruby class (String, Integer, Float, Array, Hash, etc.) |
| `subtype` | Class | Element type for Array/Set, or value type for Hash |
| `type_ref` | Boolean | Store only the referenced object's ID (see Type Refs below) |
| `display_name` | String | Human-readable label for the field |
| `extra_attrs` | Hash | Arbitrary metadata passed through to `to_schema_object` |

### Instance Methods (generated for every field)

Every schema-applied class gets:

| Method | Description |
|---|---|
| `initialize(hash = nil)` | Seed from a hash; auto-generates a UUID `id` if not provided |
| `id` / `id=` | Always present, validated as a required String |
| `<field>` / `<field>=` | Getter/setter per defined field; setter validates type immediately |
| `validate` | Checks all required fields and types; raises `Schema::ValidationError` on failure |
| `to_schema_object` | Returns the internal `@json` hash (JSON-safe) |
| `from_schema_object(hash)` | Class method; equivalent to `MyClass.new(hash)` |
| `merge!(hash)` | Merges a hash into the instance's internal state |
| `==` | Equality by JSON content, not object identity |
| `schema` | Class method; returns the Schema object |
| `is_schema_class?` | Class method; returns `true` |

---

## Types

### Standard Types

Any Ruby class works as a `type` or `subtype`: `String`, `Integer`, `Float`, `Array`, `Hash`, `Symbol`, etc.

### Built-in Custom Types

Two types are provided for common cases that Ruby's standard type system doesn't cover well:

- **`SchemaType::Boolean`** — matches `true` or `false` (TrueClass / FalseClass)
- **`SchemaType::Date`** — matches `Date` and `DateTime`

```ruby
schema.fields = {
  "active"     => { type: SchemaType::Boolean },
  "created_on" => { type: SchemaType::Date }
}
```

### Custom Types

Build your own type by defining class methods on any module or class:

```ruby
module EmailType
  def self.type_match?(value)
    value.is_a?(String) && value.include?('@')
  end

  def self.field_value_validation(field, value)
    raise Schema::ValidationError, "Invalid email" unless value.match?(/\A[^@]+@[^@]+\z/)
  end

  # Optional: validate the field definition itself at schema apply time
  def self.field_def_validation(field)
    raise Schema::ValidationError, "EmailType cannot be required" if field.required
  end
end

schema.fields = {
  "email" => { type: EmailType }
}
```

### Subtype (Collections)

Use `subtype` to type-check collection contents. Validated on every `add_*` / `upsert_*` call and on `validate`.

```ruby
schema.fields = {
  "scores"  => { type: Array, subtype: Integer },
  "labels"  => { type: Hash,  subtype: String }
}

instance.add_score(42)
instance.add_score("oops")          # raises Schema::ValidationError immediately
instance.upsert_label("tier", "A")
```

---

## Array and Hash Field Methods

For `Array` (or `Set`) fields, the gem generates `add_<singular>` and `remove_<singular>` methods using a basic singularization of the field name (strip trailing `s`).

For `Hash` fields, it generates `upsert_<singular>` and `remove_<singular>`.

```ruby
schema.fields = {
  "tags"     => { type: Array, subtype: String },
  "metadata" => { type: Hash,  subtype: String }
}

instance.add_tag("ruby")
instance.remove_tag("ruby")
instance.upsert_metadatum("color", "blue")
instance.remove_metadatum("color")
```

---

## Validation

`validate` checks all fields in order:

1. **required** — field must be non-nil and non-empty
2. **type** — value must match the declared `type`
3. **subtype** — each element must match `subtype` (for collections)
4. **custom** — calls `field_value_validation` on the type if it responds to it

Errors name the class and field: `"Invalid Product (field: price): 'price' is a required field and wasn't found"`.

Setters also validate type immediately on assignment — you don't have to wait for an explicit `validate` call to catch a type mismatch.

```ruby
instance = Product.new
instance.validate
# => Schema::ValidationError: Invalid Product (field: name): 'name' is a required field...

instance.name  = "Widget"
instance.price = "not a float"
# => Schema::ValidationError: 'price' is expecting type 'Float' but found 'String'
```

---

## Type Refs

A `type_ref` field stores a reference to another schema object by ID rather than embedding the full object. This keeps your JSON flat and avoids duplication.

**Rules when assigning a type_ref field:**
- Assign a full object whose `id` already exists in storage → collapsed to its ID string
- Assign a full object whose `id` does not exist in storage → `save!` is called on it automatically, then collapsed to ID
- Assign an ID string directly → validated that it exists, stored as-is

```ruby
class Item
  # ... schema with storage applied
end

class Order
  schema = Schema.new
  schema.key = "order"
  schema.fields = {
    "item"  => { type: Item,  type_ref: true },
    "items" => { type: Array, subtype: Item, type_ref: true }
  }
  apply_schema schema
end

order = Order.new

existing = Item.new({ 'id' => '123' })
# Item.exist?('123') returns true → stored as '123'
order.item = existing
order.to_schema_object  # => { ..., "item" => "123" }

new_item = Item.new({ 'id' => '456' })
# Item.exist?('456') returns false → new_item.save! is called → stored as '456'
order.item = new_item

order.item = '789'
# Item.exist?('789') returns true → stored as '789'
```

---

## Nested Schemas

Fields whose `type` is another schema class are serialized as a nested hash and reconstructed automatically on access.

```ruby
class Address
  schema = Schema.new
  schema.key = "address"
  schema.fields = { "street" => { type: String }, "city" => { type: String } }
  apply_schema schema
end

class Person
  schema = Schema.new
  schema.key = "person"
  schema.fields = { "address" => { type: Address } }
  apply_schema schema
end

p = Person.new
p.address = Address.new({ 'street' => '1 Main St', 'city' => 'Springfield' })
p.to_schema_object
# => { "id" => "...", "address" => { "id" => "...", "street" => "1 Main St", "city" => "Springfield" } }
p.address.city  # => "Springfield" (reconstructed as Address instance)
```

---

## Storage

Require the storage entry point to get file-backed persistence:

```ruby
require 'ruby-schema-storage'
```

### Setup

```ruby
storage = SchemaTypeStorage.new('data')  # 'data' is the directory for JSON files

class Product
  schema = Schema.new
  schema.key        = "product"
  schema.display_name = "Product"
  schema.storage    = storage
  schema.accessors  = [:get, :list, :exist?, :save!, :delete!]
  schema.fields     = {
    "name"  => { required: true, type: String },
    "price" => { required: true, type: Float }
  }
  apply_schema schema
end
```

You can apply any subset of `[:get, :list, :exist?, :save!, :delete!]` — only the methods you list are generated.

### CRUD Operations

```ruby
# Class methods
product = Product.get('some-uuid')
products = Product.list
exists = Product.exist?('some-uuid')

# Instance methods
product = Product.new({ 'name' => 'Widget', 'price' => 9.99 })
product.save!    # validates, sets updated_at, writes to file
product.delete!  # soft delete: sets deleted: true, does not remove from file
```

### Filtering

Both `get` and `list` accept options:

```ruby
# Only return records updated after a timestamp (ISO8601 string)
Product.list(since: '2025-01-01T00:00:00Z')
Product.get('some-id', since: '2025-01-01T00:00:00Z')

# Include soft-deleted records (excluded by default)
Product.list(include_deleted: true)
```

### Storage Internals

- Each table is stored as `data/<schema.key>.json`
- All writes are write-through: cache is updated first, then the full table is written to disk
- The cache is loaded lazily on first access per table
- Thread-safe: one `Mutex` per table in `LocalFilesDb`
- Call `storage.clear_cache` to force a reload from disk (e.g. after an external write)

---

## Build and Install

```bash
gem build ruby-schema.gemspec
gem install ruby-schema-0.6.2.gem
```
