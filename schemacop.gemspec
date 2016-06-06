# -*- encoding: utf-8 -*-
# stub: schemacop 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "schemacop"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sitrox"]
  s.date = "2016-06-06"
  s.files = [".gitignore", ".releaser_config", ".rubocop.yml", ".travis.yml", ".yardopts", "Gemfile", "LICENSE", "README.md", "RUBY_VERSION", "Rakefile", "VERSION", "doc/Schemacop.html", "doc/Schemacop/Exceptions.html", "doc/Schemacop/Exceptions/Base.html", "doc/Schemacop/Exceptions/InvalidSchema.html", "doc/Schemacop/Exceptions/Validation.html", "doc/Schemacop/Validator.html", "doc/_index.html", "doc/class_list.html", "doc/css/common.css", "doc/css/full_list.css", "doc/css/style.css", "doc/file.README.html", "doc/file_list.html", "doc/frames.html", "doc/index.html", "doc/js/app.js", "doc/js/full_list.js", "doc/js/jquery.js", "doc/method_list.html", "doc/top-level-namespace.html", "lib/schemacop.rb", "lib/schemacop/exceptions.rb", "lib/schemacop/validator.rb", "schemacop.gemspec", "test/schemacop_validator_test.rb"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "Schemacop validates ruby structures consisting of nested hashes and arrays against simple schema definitions."
  s.test_files = ["test/schemacop_validator_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<ci_reporter>, ["~> 2.0"])
      s.add_development_dependency(%q<ci_reporter_minitest>, [">= 0"])
      s.add_development_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<haml>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<rubocop>, ["~> 0.35"])
      s.add_development_dependency(%q<redcarpet>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<ci_reporter>, ["~> 2.0"])
      s.add_dependency(%q<ci_reporter_minitest>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<haml>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<rubocop>, ["~> 0.35"])
      s.add_dependency(%q<redcarpet>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<ci_reporter>, ["~> 2.0"])
    s.add_dependency(%q<ci_reporter_minitest>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<haml>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<rubocop>, ["~> 0.35"])
    s.add_dependency(%q<redcarpet>, [">= 0"])
  end
end