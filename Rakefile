task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'schemacop'
    spec.version       = IO.read('VERSION').chomp
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
    spec.add_dependency 'sorbet-runtime', '0.4.4667'
    spec.add_development_dependency 'bundler'
    spec.add_development_dependency 'minitest'
    spec.add_development_dependency 'minitest-reporters'
    spec.add_development_dependency 'colorize'
    spec.add_development_dependency 'rubocop', '0.35.1'
    spec.add_development_dependency 'pry'
  end

  File.open('schemacop.gemspec', 'w') { |f| f.write(gemspec.to_ruby.strip) }
end

# rubocop: disable Lint/HandleExceptions
begin
  require 'rake/testtask'
  Rake::TestTask.new do |t|
    t.pattern = 'test/unit/**/*_test.rb'
    t.verbose = false
    t.libs << 'test/lib'
  end
rescue LoadError
end
