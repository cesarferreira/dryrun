# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atry/version'


#rake build    # Build sinderella-0.0.1.gem into the pkg directory
#rake install  # Build and install sinderella-0.0.1.gem into system gems
#rake release  # Create tag v0.0.1 and build and push sinderella-0.0.1.gem t...
#rake spec     # Run RSpec code examples

Gem::Specification.new do |spec|
  spec.name          = "atry"
  spec.version       = Atry::VERSION
  spec.authors       = ["cesar ferreira"]
  spec.email         = ["cesar.manuel.ferreira@gmail.com"]

  spec.summary       = %q{try an android library directly from the command line}
  spec.description   = %q{try an android library directly from the command line}
  spec.homepage      = "https://github.com/cesarferreira/atry"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'pry-byebug', '~> 3.1'

  spec.add_dependency 'colorize',  '~> 0.7'

end
