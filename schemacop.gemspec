# -*- encoding: utf-8 -*-
# stub: schemacop 2.4.5 ruby lib

Gem::Specification.new do |s|
  s.name = "schemacop".freeze
  s.version = "2.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2020-05-13"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "RUBY_VERSION".freeze, "Rakefile".freeze, "VERSION".freeze, "doc/Schemacop.html".freeze, "doc/Schemacop/ArrayValidator.html".freeze, "doc/Schemacop/BooleanValidator.html".freeze, "doc/Schemacop/Caster.html".freeze, "doc/Schemacop/Collector.html".freeze, "doc/Schemacop/Dupper.html".freeze, "doc/Schemacop/Exceptions.html".freeze, "doc/Schemacop/Exceptions/InvalidSchemaError.html".freeze, "doc/Schemacop/Exceptions/ValidationError.html".freeze, "doc/Schemacop/FieldNode.html".freeze, "doc/Schemacop/FloatValidator.html".freeze, "doc/Schemacop/HashValidator.html".freeze, "doc/Schemacop/IntegerValidator.html".freeze, "doc/Schemacop/NilValidator.html".freeze, "doc/Schemacop/Node.html".freeze, "doc/Schemacop/NodeResolver.html".freeze, "doc/Schemacop/NodeSupportingField.html".freeze, "doc/Schemacop/NodeSupportingType.html".freeze, "doc/Schemacop/NodeWithBlock.html".freeze, "doc/Schemacop/NumberValidator.html".freeze, "doc/Schemacop/ObjectValidator.html".freeze, "doc/Schemacop/RootNode.html".freeze, "doc/Schemacop/Schema.html".freeze, "doc/Schemacop/StringValidator.html".freeze, "doc/Schemacop/SymbolValidator.html".freeze, "doc/ScopedEnv.html".freeze, "doc/_index.html".freeze, "doc/class_list.html".freeze, "doc/css/common.css".freeze, "doc/css/full_list.css".freeze, "doc/css/style.css".freeze, "doc/file.README.html".freeze, "doc/file_list.html".freeze, "doc/frames.html".freeze, "doc/index.html".freeze, "doc/inheritance.graphml".freeze, "doc/inheritance.pdf".freeze, "doc/js/app.js".freeze, "doc/js/full_list.js".freeze, "doc/js/jquery.js".freeze, "doc/method_list.html".freeze, "doc/top-level-namespace.html".freeze, "lib/schemacop.rb".freeze, "lib/schemacop/caster.rb".freeze, "lib/schemacop/collector.rb".freeze, "lib/schemacop/dupper.rb".freeze, "lib/schemacop/exceptions.rb".freeze, "lib/schemacop/field_node.rb".freeze, "lib/schemacop/node.rb".freeze, "lib/schemacop/node_resolver.rb".freeze, "lib/schemacop/node_supporting_field.rb".freeze, "lib/schemacop/node_supporting_type.rb".freeze, "lib/schemacop/node_with_block.rb".freeze, "lib/schemacop/root_node.rb".freeze, "lib/schemacop/schema.rb".freeze, "lib/schemacop/scoped_env.rb".freeze, "lib/schemacop/validator/array_validator.rb".freeze, "lib/schemacop/validator/boolean_validator.rb".freeze, "lib/schemacop/validator/float_validator.rb".freeze, "lib/schemacop/validator/hash_validator.rb".freeze, "lib/schemacop/validator/integer_validator.rb".freeze, "lib/schemacop/validator/nil_validator.rb".freeze, "lib/schemacop/validator/number_validator.rb".freeze, "lib/schemacop/validator/object_validator.rb".freeze, "lib/schemacop/validator/string_validator.rb".freeze, "lib/schemacop/validator/symbol_validator.rb".freeze, "schemacop.gemspec".freeze, "test/casting_test.rb".freeze, "test/collector_test.rb".freeze, "test/custom_check_test.rb".freeze, "test/custom_if_test.rb".freeze, "test/defaults_test.rb".freeze, "test/empty_test.rb".freeze, "test/nil_dis_allow_test.rb".freeze, "test/node_resolver_test.rb".freeze, "test/short_forms_test.rb".freeze, "test/test_helper.rb".freeze, "test/types_test.rb".freeze, "test/validator_array_test.rb".freeze, "test/validator_boolean_test.rb".freeze, "test/validator_float_test.rb".freeze, "test/validator_hash_test.rb".freeze, "test/validator_integer_test.rb".freeze, "test/validator_nil_test.rb".freeze, "test/validator_number_test.rb".freeze, "test/validator_object_test.rb".freeze, "test/validator_string_test.rb".freeze, "test/validator_symbol_test.rb".freeze]
  s.homepage = "https://github.com/sitrox/schemacop".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Schemacop validates ruby structures consisting of nested hashes and arrays against simple schema definitions.".freeze
  s.test_files = ["test/casting_test.rb".freeze, "test/collector_test.rb".freeze, "test/custom_check_test.rb".freeze, "test/custom_if_test.rb".freeze, "test/defaults_test.rb".freeze, "test/empty_test.rb".freeze, "test/nil_dis_allow_test.rb".freeze, "test/node_resolver_test.rb".freeze, "test/short_forms_test.rb".freeze, "test/test_helper.rb".freeze, "test/types_test.rb".freeze, "test/validator_array_test.rb".freeze, "test/validator_boolean_test.rb".freeze, "test/validator_float_test.rb".freeze, "test/validator_hash_test.rb".freeze, "test/validator_integer_test.rb".freeze, "test/validator_nil_test.rb".freeze, "test/validator_number_test.rb".freeze, "test/validator_object_test.rb".freeze, "test/validator_string_test.rb".freeze, "test/validator_symbol_test.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<ci_reporter>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<ci_reporter_minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<haml>.freeze, [">= 0"])
      s.add_development_dependency(%q<colorize>.freeze, [">= 0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
      s.add_development_dependency(%q<redcarpet>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    else
      s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<ci_reporter>.freeze, ["~> 2.0"])
      s.add_dependency(%q<ci_reporter_minitest>.freeze, [">= 0"])
      s.add_dependency(%q<haml>.freeze, [">= 0"])
      s.add_dependency(%q<colorize>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
      s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 4.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<ci_reporter>.freeze, ["~> 2.0"])
    s.add_dependency(%q<ci_reporter_minitest>.freeze, [">= 0"])
    s.add_dependency(%q<haml>.freeze, [">= 0"])
    s.add_dependency(%q<colorize>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.35.1"])
    s.add_dependency(%q<redcarpet>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
  end
end