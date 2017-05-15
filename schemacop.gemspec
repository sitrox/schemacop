# -*- encoding: utf-8 -*-
# stub: schemacop 2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "schemacop".freeze
  s.version = "2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2017-05-15"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "RUBY_VERSION".freeze, "Rakefile".freeze, "VERSION".freeze, "doc/inheritance.graphml".freeze, "doc/inheritance.pdf".freeze, "lib/schemacop.rb".freeze, "lib/schemacop/collector.rb".freeze, "lib/schemacop/exceptions.rb".freeze, "lib/schemacop/field_node.rb".freeze, "lib/schemacop/node.rb".freeze, "lib/schemacop/node_resolver.rb".freeze, "lib/schemacop/node_supporting_field.rb".freeze, "lib/schemacop/node_supporting_type.rb".freeze, "lib/schemacop/node_with_block.rb".freeze, "lib/schemacop/root_node.rb".freeze, "lib/schemacop/schema.rb".freeze, "lib/schemacop/scoped_env.rb".freeze, "lib/schemacop/validator/array_validator.rb".freeze, "lib/schemacop/validator/boolean_validator.rb".freeze, "lib/schemacop/validator/float_validator.rb".freeze, "lib/schemacop/validator/hash_validator.rb".freeze, "lib/schemacop/validator/integer_validator.rb".freeze, "lib/schemacop/validator/nil_validator.rb".freeze, "lib/schemacop/validator/number_validator.rb".freeze, "lib/schemacop/validator/object_validator.rb".freeze, "lib/schemacop/validator/string_validator.rb".freeze, "schemacop.gemspec".freeze, "test/custom_check_test.rb".freeze, "test/custom_if_test.rb".freeze, "test/nil_dis_allow_test.rb".freeze, "test/short_forms_test.rb".freeze, "test/test_helper.rb".freeze, "test/types_test.rb".freeze, "test/validator_array_test.rb".freeze, "test/validator_boolean_test.rb".freeze, "test/validator_float_test.rb".freeze, "test/validator_hash_test.rb".freeze, "test/validator_integer_test.rb".freeze, "test/validator_nil_test.rb".freeze, "test/validator_number_test.rb".freeze, "test/validator_object_test.rb".freeze, "test/validator_string_test.rb".freeze]
  s.homepage = "https://github.com/sitrox/schemacop".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Schemacop validates ruby structures consisting of nested hashes and arrays against simple schema definitions.".freeze
  s.test_files = ["test/custom_check_test.rb".freeze, "test/custom_if_test.rb".freeze, "test/nil_dis_allow_test.rb".freeze, "test/short_forms_test.rb".freeze, "test/test_helper.rb".freeze, "test/types_test.rb".freeze, "test/validator_array_test.rb".freeze, "test/validator_boolean_test.rb".freeze, "test/validator_float_test.rb".freeze, "test/validator_hash_test.rb".freeze, "test/validator_integer_test.rb".freeze, "test/validator_nil_test.rb".freeze, "test/validator_number_test.rb".freeze, "test/validator_object_test.rb".freeze, "test/validator_string_test.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<ci_reporter>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<ci_reporter_minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_development_dependency(%q<haml>.freeze, [">= 0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
      s.add_development_dependency(%q<redcarpet>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<ci_reporter>.freeze, ["~> 2.0"])
      s.add_dependency(%q<ci_reporter_minitest>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<haml>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
      s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<ci_reporter>.freeze, ["~> 2.0"])
    s.add_dependency(%q<ci_reporter_minitest>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<haml>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
    s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
  end
end