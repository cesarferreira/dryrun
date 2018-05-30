# coding: utf-8
require File.join([File.dirname(__FILE__), 'lib', 'dryrun', 'version.rb'])

# rake build    # Build dryrun-0.0.1.gem into the pkg directory
# rake install  # Build and install dryrun-0.0.1.gem into system gems
# rake release  # Create tag v0.0.1 and build and push dryrun-0.0.1.gem t...
# rake spec     # Run RSpec code examples

Gem::Specification.new do |s|
  s.name          = 'dryrun'
  s.version       = Dryrun::VERSION
  s.authors       = ['cesar ferreira']
  s.email         = ['cesar.manuel.ferreira@gmail.com']

  s.summary       = 'Tool to try any android library hosted online directly from the command line'
  s.homepage      = 'http://cesarferreira.com'
  s.license       = 'MIT'
  s.platform      = Gem::Platform::RUBY

  s.files         = `git ls-files`.split("
")
  s.bindir        = 'bin'
  s.require_paths << 'lib'
  s.executables   << 'dryrun'

  s.required_ruby_version = '>= 2.0.0'

  s.add_development_dependency 'rake', '>= 12.3'
  s.add_development_dependency 'pry-byebug', '>= 3.6'
  s.add_development_dependency 'rspec', '>= 3.7'

  s.add_dependency 'bundler', '>= 1.16'
  s.add_dependency 'colorize', '>= 0.8'
  s.add_dependency 'oga', '>= 2.15'
  s.add_dependency 'highline', '>= 1.7'
  s.add_dependency 'rjb', '>= 1.5'
end
