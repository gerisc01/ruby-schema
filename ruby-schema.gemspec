require_relative 'version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-schema"
  spec.version       = RubySchema::VERSION
  spec.authors       = ["Scott Gerike"]
  spec.email         = ["scott.gerike@gmail.com"]

  spec.summary       = "A quick ruby schema creator that is meant to create schemas and then attach them to modules"
  spec.description   = <<-DESC
A barebones ruby schema creator that allows you to attach created schemas to your modules.

It also allows you to handle references to other objects and it handles saving and converting to id to allow you to save
the space of referring to the whole object when you just need the id. 
  DESC
  spec.homepage      = "https://github.com/gerisc01/ruby-schema"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gerisc01/ruby-schema"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{(/schema_storage/test/|/schema/test/)}) }
                     .reject { |f| f.match(%r{ruby-schema-[\d.]+\.gem}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
