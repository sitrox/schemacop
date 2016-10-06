# -*- encoding: utf-8 -*-
# stub: schemacop 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "schemacop".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2016-10-06"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "RUBY_VERSION".freeze, "Rakefile".freeze, "VERSION".freeze, "doc/Schemacop.html".freeze, "doc/Schemacop/Exceptions.html".freeze, "doc/Schemacop/Exceptions/Base.html".freeze, "doc/Schemacop/Exceptions/InvalidSchema.html".freeze, "doc/Schemacop/Exceptions/Validation.html".freeze, "doc/Schemacop/MethodValidation.html".freeze, "doc/Schemacop/MethodValidation/ClassMethods.html".freeze, "doc/Schemacop/Validator.html".freeze, "doc/_index.html".freeze, "doc/class_list.html".freeze, "doc/css/common.css".freeze, "doc/css/full_list.css".freeze, "doc/css/style.css".freeze, "doc/file.README.html".freeze, "doc/file_list.html".freeze, "doc/frames.html".freeze, "doc/index.html".freeze, "doc/js/app.js".freeze, "doc/js/full_list.js".freeze, "doc/js/jquery.js".freeze, "doc/method_list.html".freeze, "doc/top-level-namespace.html".freeze, "lib/schemacop.rb".freeze, "lib/schemacop/exceptions.rb".freeze, "lib/schemacop/validator.rb".freeze, "schemacop.gemspec".freeze, "test/schemacop_validator_test.rb".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Schemacop validates ruby structures consisting of nested hashes and arrays against simple schema definitions.".freeze
  s.test_files = ["test/schemacop_validator_test.rb".freeze]

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