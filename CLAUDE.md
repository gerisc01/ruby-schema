# ruby-schema — Codebase Guide

## What This Is

A Ruby gem that lets you define a schema once and apply it to any class, automatically generating field accessors with type validation. An optional storage layer adds file-backed persistence with an in-memory cache and soft deletes. Built to reduce boilerplate in API services.

**Entry points:**
- `require 'ruby-schema'` — schema + validation only
- `require 'ruby-schema-storage'` — also loads the storage layer

**Run tests:** `rake test`

---

## Core Concepts

| Concept | What it is |
|---|---|
| `Schema` | Configuration object: holds `key`, `display_name`, and `fields`. Calling `apply_schema(schema)` on a class mixes in all generated methods. |
| `Field` | Metadata for one field: `key`, `type`, `subtype`, `required`, `type_ref`, `extra_attrs`. Created from the hash you pass to `schema.fields=`. |
| `@json` | The single internal data store for every schema instance. All getters read from it, all setters write to it. `to_schema_object` just returns `@json`. |
| `type_ref` | A field flag meaning "store only the ID, not the full object." On assignment, if the object doesn't exist in storage it is auto-saved; if it does, it is collapsed to its ID string. |
| `subtype` | The element type for `Array`/`Set` fields, or the value type for `Hash` fields. Validated on every mutation. |
| Custom type | A class that responds to `type_match?(value)` (for runtime checks) and optionally `field_def_validation(field)` (for schema-time checks) and `field_value_validation(field, value)` (for value-level custom logic). Built-ins: `SchemaType::Boolean`, `SchemaType::Date`. |
| `SchemaTypeStorage` | Orchestrates persistence: wraps `LocalCache` (in-memory Hash) + `LocalFilesDb` (JSON files). Cache is loaded lazily per table on first access and cleared manually via `clear_cache`. |
| Soft delete | `delete!` sets `deleted: true` and `updated_at` on the record; it is never removed from the file. `list`/`get` filter it out unless `include_deleted: true` is passed. |

---

## Module Map

```
lib/
├── ruby-schema.rb                        Entry point for schema-only usage
├── ruby-schema-storage.rb                Entry point when storage is also needed
│
├── schema/src/
│   ├── schema.rb                         Schema class: holds config, drives apply(), drives validate()
│   ├── field.rb                          Field class: metadata + per-field validate(); built from hash via from_schema_object()
│   ├── errors.rb                         Schema::ValidationError (shared by both layers)
│   ├── field_types.rb                    Requires all four field_types modules
│   ├── custom_types.rb                   Requires SchemaType::Boolean and SchemaType::Date
│   │
│   ├── field_types/
│   │   ├── base_fields.rb                Mixes in: initialize, validate, to_schema_object, from_schema_object, merge!, ==
│   │   ├── top_level_fields.rb           Generates getter/setter for every field; setter validates + handles type_ref
│   │   ├── array_fields.rb               Generates add_<singular> / remove_<singular> for Array/Set fields
│   │   └── hash_fields.rb                Generates upsert_<singular> / remove_<singular> for Hash fields
│   │
│   ├── custom_types/
│   │   ├── boolean.rb                    SchemaType::Boolean — matches TrueClass and FalseClass
│   │   └── date.rb                       SchemaType::Date — matches Date and DateTime
│   │
│   └── helpers/
│       ├── validators.rb                 All validation logic: required, type, subtype, type_ref_exists, field_value_validation
│       ├── field_helpers.rb              Converts between @json generic values and typed Ruby objects (e.g. nested schema hashes)
│       └── type_ref.rb                   TypeRef.process_type_ref: collapses object-or-id to stored ID, auto-saves if new
│
└── schema_storage/src/
    ├── schema.rb                         Reopens Schema to add :storage, :accessors attrs; overrides apply_schema to also call apply_storage
    ├── errors.rb                         Same ValidationError (kept in sync with schema/src/errors.rb)
    │
    ├── methods/
    │   └── crud_methods.rb               Generates class methods get/list/exist? and instance methods save!/delete! via define_method
    │
    └── storage/
        ├── schema_type_storage.rb        Orchestrator: cache-aside reads, write-through saves, lazy cache load per table
        ├── local_cache.rb                In-memory nested Hash; keyed by [table][id]; 'all_ids' is a reserved key per table
        └── local_files_db.rb             JSON file per table at data/<table>.json; Mutex per table for thread safety
```

---

## Architecture

```
                    apply_schema(schema)
                          │
              ┌───────────▼───────────┐
              │     Schema#apply      │
              │   (schema.rb:27)      │
              └──┬──────┬──────┬──────┘
                 │      │      │
         BaseFields  TopLevel  Array/Hash
         (init,     Fields     Fields
         validate,  (getter/   (add_*/
         ==, etc)   setter)    upsert_*)
                 │
         All methods stored in @json

                 Storage (optional)
          ┌──────────────────────────┐
          │   Schema#apply_storage   │
          │  (schema_storage/src/    │
          │   schema.rb:19)          │
          └──────────┬───────────────┘
                     │
              CrudMethods.apply
              (defines get/list/
               exist?/save!/delete!)
                     │
           SchemaTypeStorage
           ┌──────┴──────┐
       LocalCache    LocalFilesDb
       (in-memory)   (data/*.json)
```

---

## Key Data Flows

**Setting a field value** (`instance.name = "foo"`):
1. `TopLevelFields` setter (top_level_fields.rb:26) — validates type via `field.validate(value)`
2. If `type_ref`: `TypeRef.process_type_ref` collapses to ID string, auto-saves if needed
3. `FieldHelpers.field_type_to_generic` converts typed object to JSON-safe value
4. Stored in `self.json[field.key]`

**Getting a field value** (`instance.name`):
1. `TopLevelFields` getter (top_level_fields.rb:19)
2. `FieldHelpers.generic_to_field_type` converts stored JSON value back to typed object (e.g. reconstructs nested schema instances)

**Calling `validate`**:
1. `Schema#validate` iterates each field, reads current value
2. Each `Field#validate` calls: `Validators.required` → `Validators.type` → `Validators.subtype` → `Validators.field_value_validation`
3. Raises `Schema::ValidationError` with field name and class on first failure

**Calling `save!`**:
1. `CrudMethods` instance method calls `self.validate` first (hard stop on invalid state)
2. `SchemaTypeStorage#save` sets `updated_at` to current UTC ISO8601
3. Writes to `LocalCache` then immediately persists full table to `LocalFilesDb` (write-through)
4. Maintains `all_ids` list in cache (used by `list`)

**Calling `list`**:
1. `SchemaTypeStorage#list` loads cache from file if not yet loaded for this table
2. Reads `all_ids` from cache, maps each to its cached object
3. Filters by `since:` (updated_at comparison) and/or removes `deleted: true` records
4. `CrudMethods` maps each JSON hash through `clazz.new(json)`

---

## Debugging Starting Points

| Symptom | Where to look |
|---|---|
| ValidationError on field set | `lib/schema/src/helpers/validators.rb` — check `type`, `subtype` logic |
| ValidationError on validate call | `lib/schema/src/schema.rb:36` — `Schema#validate` iterates fields; `lib/schema/src/field.rb:7` — `Field#validate` |
| Getter returning wrong type / nil | `lib/schema/src/helpers/field_helpers.rb` — `generic_to_field_type` conversion |
| Nested schema not round-tripping | `lib/schema/src/helpers/field_helpers.rb` — look at how nested schema objects are serialized/deserialized |
| type_ref not collapsing to ID | `lib/schema/src/helpers/type_ref.rb` — `TypeRef.process_type_ref` |
| add_*/remove_*/upsert_* not working | `lib/schema/src/field_types/array_fields.rb` or `hash_fields.rb` |
| Storage not persisting | `lib/schema_storage/src/storage/local_files_db.rb` — file path, mutex, JSON write |
| Cache returning stale data | `lib/schema_storage/src/storage/schema_type_storage.rb` — `clear_cache`, `load_cache_from_db` |
| CRUD method not defined on class | `lib/schema_storage/src/methods/crud_methods.rb` — check `apply` and which methods are in `schema.accessors` |
| Custom type not validating | `lib/schema/src/helpers/validators.rb:61` — `general_type_check` calls `type_match?`; `lib/schema/src/field.rb:30` — `field_def_validation` |

---

## Non-Obvious Design Decisions

**`@json` as the sole internal store.** Every field getter/setter goes through `@json`. This means `to_schema_object` is free (just returns `@json`) and `initialize` from a hash is also free. The cost is that getters must convert back to typed objects on every read via `FieldHelpers`.

**Setters validate eagerly, `validate` validates lazily.** Calling `instance.name = 123` on a String field raises immediately. But `validate` re-checks everything — it's not redundant, it catches fields that were never set at all (required check).

**`type_ref` auto-saves.** When you assign an object to a type_ref field and it doesn't exist in storage yet, `TypeRef.process_type_ref` calls `.save!` on it automatically. This is a side effect of assignment that isn't obvious from the call site.

**`include_deleted` default is exclusion.** The option name is slightly counter-intuitive: `include_deleted: false` (the default) means deleted records are filtered OUT. Passing `include_deleted: true` means include them. The method `include_deleted?(opts)` returns true when they should be excluded.

**Storage cache is never TTL-expired.** The cache lives for the lifetime of the `SchemaTypeStorage` instance. If multiple processes write to the same data files, each process has a stale cache. Call `clear_cache` to reload from disk.

**`all_ids` is a magic key.** `LocalCache` stores a list of all IDs for a table under the key `'all_ids'`. `persist_without_all_ids` strips this before writing to disk so it doesn't pollute the JSON file.

**`schema.rb` is overridden by storage.** `ruby-schema-storage.rb` reopens the `Object` class and replaces `apply_schema` to also call `apply_storage`. If both files are required, load order matters — storage's version wins.

---

## Test Map

| Test file | Covers |
|---|---|
| `lib/schema/test/unit/base_fields_test.rb` | `BaseFields`: initialize, equality, merge!, to_schema_object |
| `lib/schema/test/unit/top_level_fields_test.rb` | `TopLevelFields`: getter/setter, type validation on set |
| `lib/schema/test/unit/array_fields_test.rb` | `ArrayFields`: add_*, remove_*, subtype validation |
| `lib/schema/test/unit/hash_fields_test.rb` | `HashFields`: upsert_*, remove_*, subtype validation |
| `lib/schema/test/unit/field_test.rb` | `Field`: from_schema_object, validate_def, extra_attrs |
| `lib/schema/test/unit/field_helpers_test.rb` | `FieldHelpers`: type conversions in/out of @json |
| `lib/schema/test/unit/custom_types_test.rb` | `SchemaType::Boolean`, `SchemaType::Date` type_match? |
| `lib/schema/test/unit/nested_schemas_test.rb` | Nested schema serialization/deserialization round-trips |
| `lib/schema/test/integration/integration_test.rb` | End-to-end: schema definition, apply, validate, type_refs |
| `lib/schema_storage/test/unit/crud_methods_test.rb` | `CrudMethods`: method generation, invocation |
| `lib/schema_storage/test/unit/schema_type_storage_unit_test.rb` | `SchemaTypeStorage` + `LocalCache` unit behavior |
| `lib/schema_storage/test/integration/schema_type_storage_test.rb` | File I/O, cache behavior, since/deleted filters |
| `lib/schema_storage/test/integration/schema_accessors_test.rb` | End-to-end: save/get/list/delete! with real storage |
