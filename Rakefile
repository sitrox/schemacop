task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'schemacop'
    spec.version       = IO.read('VERSION').chomp
    spec.authors       = ['Sitrox']
    spec.summary       = %(
      Schemacop validates ruby structures consisting of nested hashes and arrays
      against simple schema definitions.
    )
    spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    spec.executables   = []
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ['lib']

    spec.add_development_dependency 'bundler', '~> 1.3'
    spec.add_development_dependency 'rake'
    spec.add_development_dependency 'ci_reporter', '~> 2.0'
    spec.add_development_dependency 'ci_reporter_minitest'
    spec.add_development_dependency 'activesupport'
    spec.add_development_dependency 'haml'
    spec.add_development_dependency 'yard'
    spec.add_development_dependency 'rubocop', '0.35.1'
    spec.add_development_dependency 'redcarpet'
  end

  File.open('schemacop.gemspec', 'w') { |f| f.write(gemspec.to_ruby.strip) }
end

# rubocop: disable Lint/HandleExceptions
begin
  require 'rake/testtask'
  require 'ci/reporter/rake/minitest'
  Rake::TestTask.new do |t|
    t.pattern = 'test/*_test.rb'
    t.verbose = false
    t.libs << 'test'
  end
rescue LoadError
end
