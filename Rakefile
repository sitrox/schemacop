task :gemspec do
  gemspec = Gem::Specification.new do |spec|
    spec.name          = 'schemacop'
    spec.version       = IO.read('VERSION').chomp
    spec.authors       = ['Sitrox']
    spec.summary       = 'Validation of ruby structures against a schema definition.'
    spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    spec.executables   = []
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ['lib']

    spec.add_development_dependency 'bundler', '~> 1.3'
    spec.add_development_dependency 'rake'
    spec.add_development_dependency 'rspec'
    spec.add_development_dependency 'ci_reporter', '~> 2.0'
    spec.add_development_dependency 'ci_reporter_rspec'
    spec.add_development_dependency 'activerecord'
    spec.add_development_dependency 'haml'
    spec.add_development_dependency 'yard'
    spec.add_development_dependency 'redcarpet'
  end

  File.open('schemacop.gemspec', 'w') { |f| f.write(gemspec.to_ruby.strip) }
end

# rubocop: disable Lint/HandleExceptions

begin
  require 'rspec/core/rake_task'
  require 'ci/reporter/rake/rspec'
  RSpec::Core::RakeTask.new(:spec)
  task spec: 'ci:setup:rspec'
  task test: :spec
rescue LoadError
end
