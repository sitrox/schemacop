task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'schemacop'
    spec.version       = File.read('VERSION').chomp
    spec.authors       = ['Sitrox']
    spec.summary       = %(
      Schemacop validates ruby structures consisting of nested hashes and arrays
      against simple schema definitions.
    )
    spec.license       = 'MIT'
    spec.homepage      = 'https://github.com/sitrox/schemacop'
    spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    spec.executables   = []
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ['lib']

    # This lower bound for ActiveSupport is not necessarily true. Schemacop
    # needs access to ActiveSupport::HashWithIndifferentAccess and expects
    # behavior of that as in version 5 of ActiveSupport.
    spec.add_dependency 'activesupport', '>= 4.0'
    spec.add_dependency 'ruby2_keywords', '>= 0.0.4'
    spec.add_development_dependency 'bundler'
    spec.add_development_dependency 'rake'
    spec.add_development_dependency 'minitest'
    spec.add_development_dependency 'minitest-reporters'
    spec.add_development_dependency 'colorize'
    spec.add_development_dependency 'rubocop', '1.24.1'
    spec.add_development_dependency 'pry'
    spec.add_development_dependency 'byebug'
    spec.add_development_dependency 'simplecov', '0.21.2'
  end

  File.write('schemacop.gemspec', gemspec.to_ruby.strip)
end

begin
  require 'rake/testtask'
  Rake::TestTask.new do |t|
    t.pattern = 'test/unit/**/*_test.rb'
    t.verbose = false
    t.libs << 'test/lib'
  end
end
