# frozen_string_literal: true

require_relative "lib/nested_select/version"

Gem::Specification.new do |spec|
  spec.name = "nested_select"
  spec.version = NestedSelect::VERSION
  spec.authors = ["alekseyl"]
  spec.email = ["leshchuk@gmail.com"]

  spec.summary = "ActiveRecord improved select on nested models, allows partial instantiation on nested models, easy one step improvements on performance and memory"
  spec.description = "ActiveRecord improved select on nested models, allows partial instantiation on nested models, easy one step improvements on performance and memory"
  spec.homepage = "https://github.com/alekseyl/nested_select"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alekseyl/nested_select"
  spec.metadata["changelog_uri"] = "https://github.com/alekseyl/nested_select/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activerecord", ">= 7"
  spec.add_dependency "activesupport", ">= 7"

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'bundler', '>= 1.11'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rails-i18n', '>=4'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'stubberry'
  spec.add_development_dependency 'rails_sql_prettifier'
  spec.add_development_dependency 'amazing_print'
  spec.add_development_dependency 'rubocop-shopify'
  spec.add_development_dependency "appraisal"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
