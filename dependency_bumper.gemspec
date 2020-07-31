require_relative 'lib/dependency_bumper/version'

Gem::Specification.new do |spec|
  spec.name          = 'dependency_bumper'
  spec.version       = DependencyBumper::VERSION
  spec.authors       = ['can eldem']
  spec.email         = ['eldemcan@gmail.com']

  spec.summary       = %q{ Tool helps you to automate updating dependencies of your Ruby project. }
  spec.homepage      = 'https://github.com/spandx/dependency_bumper'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  # spec.metadata['allowed_push_host'] = 'TODO: Set to 'http://mygemserver.com''

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/spandx/dependency_bumper'
  spec.metadata['changelog_uri'] = 'https://github.com/spandx/dependency_bumper'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'git', '~> 1.7'
  spec.add_development_dependency 'console', '~> 1.8'
  spec.add_development_dependency 'byebug', '~> 11.1', '>= 11.1.3'
  spec.add_runtime_dependency 'bundler', '~> 2.1'
  spec.add_runtime_dependency 'zeitwerk', '~> 2.3'
end
