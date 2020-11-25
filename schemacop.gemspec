# -*- encoding: utf-8 -*-
# stub: schemacop 2.4.7 ruby lib

Gem::Specification.new do |s|
  s.name = "schemacop".freeze
  s.version = "2.4.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2020-11-24"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "README_V2.md".freeze, "RUBY_VERSION".freeze, "Rakefile".freeze, "VERSION".freeze, "lib/schemacop.rb".freeze, "lib/schemacop/all_of_node.rb".freeze, "lib/schemacop/any_of_node.rb".freeze, "lib/schemacop/array_node.rb".freeze, "lib/schemacop/boolean_node.rb".freeze, "lib/schemacop/combination_node.rb".freeze, "lib/schemacop/context.rb".freeze, "lib/schemacop/exceptions.rb".freeze, "lib/schemacop/global_context.rb".freeze, "lib/schemacop/integer_node.rb".freeze, "lib/schemacop/is_not_node.rb".freeze, "lib/schemacop/node.rb".freeze, "lib/schemacop/number_node.rb".freeze, "lib/schemacop/numeric_node.rb".freeze, "lib/schemacop/object_node.rb".freeze, "lib/schemacop/one_of_node.rb".freeze, "lib/schemacop/railtie.rb".freeze, "lib/schemacop/reference_node.rb".freeze, "lib/schemacop/result.rb".freeze, "lib/schemacop/ruby_node.rb".freeze, "lib/schemacop/scoped_env.rb".freeze, "lib/schemacop/string_node.rb".freeze, "lib/schemacop/symbol_node.rb".freeze, "lib/schemacop/v2.rb".freeze, "lib/schemacop/v2/caster.rb".freeze, "lib/schemacop/v2/collector.rb".freeze, "lib/schemacop/v2/dupper.rb".freeze, "lib/schemacop/v2/field_node.rb".freeze, "lib/schemacop/v2/node.rb".freeze, "lib/schemacop/v2/node_resolver.rb".freeze, "lib/schemacop/v2/node_supporting_field.rb".freeze, "lib/schemacop/v2/node_supporting_type.rb".freeze, "lib/schemacop/v2/node_with_block.rb".freeze, "lib/schemacop/v2/root_node.rb".freeze, "lib/schemacop/v2/schema.rb".freeze, "lib/schemacop/v2/validator/array_validator.rb".freeze, "lib/schemacop/v2/validator/boolean_validator.rb".freeze, "lib/schemacop/v2/validator/float_validator.rb".freeze, "lib/schemacop/v2/validator/hash_validator.rb".freeze, "lib/schemacop/v2/validator/integer_validator.rb".freeze, "lib/schemacop/v2/validator/nil_validator.rb".freeze, "lib/schemacop/v2/validator/number_validator.rb".freeze, "lib/schemacop/v2/validator/object_validator.rb".freeze, "lib/schemacop/v2/validator/string_validator.rb".freeze, "lib/schemacop/v2/validator/symbol_validator.rb".freeze, "schemacop.gemspec".freeze, "test/lib/test_helper.rb".freeze, "test/unit/schemacop/any_of_test.rb".freeze, "test/unit/schemacop/array_node_test.rb".freeze, "test/unit/schemacop/boolean_node_test.rb".freeze, "test/unit/schemacop/integer_node_test.rb".freeze, "test/unit/schemacop/node_test.rb".freeze, "test/unit/schemacop/number_node_test.rb".freeze, "test/unit/schemacop/object_node_test.rb".freeze, "test/unit/schemacop/reference_node_test.rb".freeze, "test/unit/schemacop/string_node_test.rb".freeze, "test/unit/schemacop/v2/casting_test.rb".freeze, "test/unit/schemacop/v2/collector_test.rb".freeze, "test/unit/schemacop/v2/custom_check_test.rb".freeze, "test/unit/schemacop/v2/custom_if_test.rb".freeze, "test/unit/schemacop/v2/defaults_test.rb".freeze, "test/unit/schemacop/v2/empty_test.rb".freeze, "test/unit/schemacop/v2/nil_dis_allow_test.rb".freeze, "test/unit/schemacop/v2/node_resolver_test.rb".freeze, "test/unit/schemacop/v2/short_forms_test.rb".freeze, "test/unit/schemacop/v2/types_test.rb".freeze, "test/unit/schemacop/v2/validator_array_test.rb".freeze, "test/unit/schemacop/v2/validator_boolean_test.rb".freeze, "test/unit/schemacop/v2/validator_float_test.rb".freeze, "test/unit/schemacop/v2/validator_hash_test.rb".freeze, "test/unit/schemacop/v2/validator_integer_test.rb".freeze, "test/unit/schemacop/v2/validator_nil_test.rb".freeze, "test/unit/schemacop/v2/validator_number_test.rb".freeze, "test/unit/schemacop/v2/validator_object_test.rb".freeze, "test/unit/schemacop/v2/validator_string_test.rb".freeze, "test/unit/schemacop/v2/validator_symbol_test.rb".freeze]
  s.homepage = "https://github.com/sitrox/schemacop".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Schemacop validates ruby structures consisting of nested hashes and arrays against simple schema definitions.".freeze
  s.test_files = ["test/lib/test_helper.rb".freeze, "test/unit/schemacop/any_of_test.rb".freeze, "test/unit/schemacop/array_node_test.rb".freeze, "test/unit/schemacop/boolean_node_test.rb".freeze, "test/unit/schemacop/integer_node_test.rb".freeze, "test/unit/schemacop/node_test.rb".freeze, "test/unit/schemacop/number_node_test.rb".freeze, "test/unit/schemacop/object_node_test.rb".freeze, "test/unit/schemacop/reference_node_test.rb".freeze, "test/unit/schemacop/string_node_test.rb".freeze, "test/unit/schemacop/v2/casting_test.rb".freeze, "test/unit/schemacop/v2/collector_test.rb".freeze, "test/unit/schemacop/v2/custom_check_test.rb".freeze, "test/unit/schemacop/v2/custom_if_test.rb".freeze, "test/unit/schemacop/v2/defaults_test.rb".freeze, "test/unit/schemacop/v2/empty_test.rb".freeze, "test/unit/schemacop/v2/nil_dis_allow_test.rb".freeze, "test/unit/schemacop/v2/node_resolver_test.rb".freeze, "test/unit/schemacop/v2/short_forms_test.rb".freeze, "test/unit/schemacop/v2/types_test.rb".freeze, "test/unit/schemacop/v2/validator_array_test.rb".freeze, "test/unit/schemacop/v2/validator_boolean_test.rb".freeze, "test/unit/schemacop/v2/validator_float_test.rb".freeze, "test/unit/schemacop/v2/validator_hash_test.rb".freeze, "test/unit/schemacop/v2/validator_integer_test.rb".freeze, "test/unit/schemacop/v2/validator_nil_test.rb".freeze, "test/unit/schemacop/v2/validator_number_test.rb".freeze, "test/unit/schemacop/v2/validator_object_test.rb".freeze, "test/unit/schemacop/v2/validator_string_test.rb".freeze, "test/unit/schemacop/v2/validator_symbol_test.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0"])
      s.add_runtime_dependency(%q<sorbet-runtime>.freeze, ["= 0.4.4667"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0"])
      s.add_development_dependency(%q<colorize>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    else
      s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
      s.add_dependency(%q<sorbet-runtime>.freeze, ["= 0.4.4667"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
      s.add_dependency(%q<colorize>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
    s.add_dependency(%q<sorbet-runtime>.freeze, ["= 0.4.4667"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
    s.add_dependency(%q<colorize>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
  end
end