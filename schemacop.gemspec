# -*- encoding: utf-8 -*-
# stub: schemacop 3.0.17 ruby lib

Gem::Specification.new do |s|
  s.name = "schemacop".freeze
  s.version = "3.0.17"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2022-06-08"
  s.files = [".github/workflows/ruby.yml".freeze, ".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "README_V2.md".freeze, "README_V3.md".freeze, "RUBY_VERSION".freeze, "Rakefile".freeze, "VERSION".freeze, "lib/schemacop.rb".freeze, "lib/schemacop/base_schema.rb".freeze, "lib/schemacop/exceptions.rb".freeze, "lib/schemacop/railtie.rb".freeze, "lib/schemacop/schema.rb".freeze, "lib/schemacop/schema2.rb".freeze, "lib/schemacop/schema3.rb".freeze, "lib/schemacop/scoped_env.rb".freeze, "lib/schemacop/v2.rb".freeze, "lib/schemacop/v2/caster.rb".freeze, "lib/schemacop/v2/collector.rb".freeze, "lib/schemacop/v2/dupper.rb".freeze, "lib/schemacop/v2/field_node.rb".freeze, "lib/schemacop/v2/node.rb".freeze, "lib/schemacop/v2/node_resolver.rb".freeze, "lib/schemacop/v2/node_supporting_field.rb".freeze, "lib/schemacop/v2/node_supporting_type.rb".freeze, "lib/schemacop/v2/node_with_block.rb".freeze, "lib/schemacop/v2/validator/array_validator.rb".freeze, "lib/schemacop/v2/validator/boolean_validator.rb".freeze, "lib/schemacop/v2/validator/float_validator.rb".freeze, "lib/schemacop/v2/validator/hash_validator.rb".freeze, "lib/schemacop/v2/validator/integer_validator.rb".freeze, "lib/schemacop/v2/validator/nil_validator.rb".freeze, "lib/schemacop/v2/validator/number_validator.rb".freeze, "lib/schemacop/v2/validator/object_validator.rb".freeze, "lib/schemacop/v2/validator/string_validator.rb".freeze, "lib/schemacop/v2/validator/symbol_validator.rb".freeze, "lib/schemacop/v3.rb".freeze, "lib/schemacop/v3/all_of_node.rb".freeze, "lib/schemacop/v3/any_of_node.rb".freeze, "lib/schemacop/v3/array_node.rb".freeze, "lib/schemacop/v3/boolean_node.rb".freeze, "lib/schemacop/v3/combination_node.rb".freeze, "lib/schemacop/v3/context.rb".freeze, "lib/schemacop/v3/dsl_scope.rb".freeze, "lib/schemacop/v3/global_context.rb".freeze, "lib/schemacop/v3/hash_node.rb".freeze, "lib/schemacop/v3/integer_node.rb".freeze, "lib/schemacop/v3/is_not_node.rb".freeze, "lib/schemacop/v3/node.rb".freeze, "lib/schemacop/v3/node_registry.rb".freeze, "lib/schemacop/v3/number_node.rb".freeze, "lib/schemacop/v3/numeric_node.rb".freeze, "lib/schemacop/v3/object_node.rb".freeze, "lib/schemacop/v3/one_of_node.rb".freeze, "lib/schemacop/v3/reference_node.rb".freeze, "lib/schemacop/v3/result.rb".freeze, "lib/schemacop/v3/string_node.rb".freeze, "lib/schemacop/v3/symbol_node.rb".freeze, "schemacop.gemspec".freeze, "test/lib/test_helper.rb".freeze, "test/schemas/nested/group.rb".freeze, "test/schemas/user.rb".freeze, "test/unit/schemacop/v2/casting_test.rb".freeze, "test/unit/schemacop/v2/collector_test.rb".freeze, "test/unit/schemacop/v2/custom_check_test.rb".freeze, "test/unit/schemacop/v2/custom_if_test.rb".freeze, "test/unit/schemacop/v2/defaults_test.rb".freeze, "test/unit/schemacop/v2/empty_test.rb".freeze, "test/unit/schemacop/v2/nil_dis_allow_test.rb".freeze, "test/unit/schemacop/v2/node_resolver_test.rb".freeze, "test/unit/schemacop/v2/short_forms_test.rb".freeze, "test/unit/schemacop/v2/types_test.rb".freeze, "test/unit/schemacop/v2/validator_array_test.rb".freeze, "test/unit/schemacop/v2/validator_boolean_test.rb".freeze, "test/unit/schemacop/v2/validator_float_test.rb".freeze, "test/unit/schemacop/v2/validator_hash_test.rb".freeze, "test/unit/schemacop/v2/validator_integer_test.rb".freeze, "test/unit/schemacop/v2/validator_nil_test.rb".freeze, "test/unit/schemacop/v2/validator_number_test.rb".freeze, "test/unit/schemacop/v2/validator_object_test.rb".freeze, "test/unit/schemacop/v2/validator_string_test.rb".freeze, "test/unit/schemacop/v2/validator_symbol_test.rb".freeze, "test/unit/schemacop/v3/all_of_node_test.rb".freeze, "test/unit/schemacop/v3/any_of_node_test.rb".freeze, "test/unit/schemacop/v3/array_node_test.rb".freeze, "test/unit/schemacop/v3/boolean_node_test.rb".freeze, "test/unit/schemacop/v3/global_context_test.rb".freeze, "test/unit/schemacop/v3/hash_node_test.rb".freeze, "test/unit/schemacop/v3/integer_node_test.rb".freeze, "test/unit/schemacop/v3/is_not_node_test.rb".freeze, "test/unit/schemacop/v3/node_test.rb".freeze, "test/unit/schemacop/v3/number_node_test.rb".freeze, "test/unit/schemacop/v3/object_node_test.rb".freeze, "test/unit/schemacop/v3/one_of_node_test.rb".freeze, "test/unit/schemacop/v3/reference_node_test.rb".freeze, "test/unit/schemacop/v3/string_node_test.rb".freeze, "test/unit/schemacop/v3/symbol_node_test.rb".freeze]
  s.homepage = "https://github.com/sitrox/schemacop".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Schemacop validates ruby structures consisting of nested hashes and arrays against simple schema definitions.".freeze
  s.test_files = ["test/lib/test_helper.rb".freeze, "test/schemas/nested/group.rb".freeze, "test/schemas/user.rb".freeze, "test/unit/schemacop/v2/casting_test.rb".freeze, "test/unit/schemacop/v2/collector_test.rb".freeze, "test/unit/schemacop/v2/custom_check_test.rb".freeze, "test/unit/schemacop/v2/custom_if_test.rb".freeze, "test/unit/schemacop/v2/defaults_test.rb".freeze, "test/unit/schemacop/v2/empty_test.rb".freeze, "test/unit/schemacop/v2/nil_dis_allow_test.rb".freeze, "test/unit/schemacop/v2/node_resolver_test.rb".freeze, "test/unit/schemacop/v2/short_forms_test.rb".freeze, "test/unit/schemacop/v2/types_test.rb".freeze, "test/unit/schemacop/v2/validator_array_test.rb".freeze, "test/unit/schemacop/v2/validator_boolean_test.rb".freeze, "test/unit/schemacop/v2/validator_float_test.rb".freeze, "test/unit/schemacop/v2/validator_hash_test.rb".freeze, "test/unit/schemacop/v2/validator_integer_test.rb".freeze, "test/unit/schemacop/v2/validator_nil_test.rb".freeze, "test/unit/schemacop/v2/validator_number_test.rb".freeze, "test/unit/schemacop/v2/validator_object_test.rb".freeze, "test/unit/schemacop/v2/validator_string_test.rb".freeze, "test/unit/schemacop/v2/validator_symbol_test.rb".freeze, "test/unit/schemacop/v3/all_of_node_test.rb".freeze, "test/unit/schemacop/v3/any_of_node_test.rb".freeze, "test/unit/schemacop/v3/array_node_test.rb".freeze, "test/unit/schemacop/v3/boolean_node_test.rb".freeze, "test/unit/schemacop/v3/global_context_test.rb".freeze, "test/unit/schemacop/v3/hash_node_test.rb".freeze, "test/unit/schemacop/v3/integer_node_test.rb".freeze, "test/unit/schemacop/v3/is_not_node_test.rb".freeze, "test/unit/schemacop/v3/node_test.rb".freeze, "test/unit/schemacop/v3/number_node_test.rb".freeze, "test/unit/schemacop/v3/object_node_test.rb".freeze, "test/unit/schemacop/v3/one_of_node_test.rb".freeze, "test/unit/schemacop/v3/reference_node_test.rb".freeze, "test/unit/schemacop/v3/string_node_test.rb".freeze, "test/unit/schemacop/v3/symbol_node_test.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0"])
      s.add_runtime_dependency(%q<ruby2_keywords>.freeze, ["= 0.0.4"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0"])
      s.add_development_dependency(%q<colorize>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 1.24.1"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, ["= 0.21.2"])
    else
      s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
      s.add_dependency(%q<ruby2_keywords>.freeze, ["= 0.0.4"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
      s.add_dependency(%q<colorize>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 1.24.1"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, ["= 0.21.2"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
    s.add_dependency(%q<ruby2_keywords>.freeze, ["= 0.0.4"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<minitest-reporters>.freeze, [">= 0"])
    s.add_dependency(%q<colorize>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 1.24.1"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<byebug>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, ["= 0.21.2"])
  end
end