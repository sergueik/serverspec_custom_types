# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ftpspec/version'

Gem::Specification.new do |spec|
  spec.name          = "ftpspec"
  spec.version       = Ftpspec::VERSION
  spec.authors       = ["Toshinari Suzuki"]
  spec.email         = ["tsnr0001@gmail.com"]
  spec.summary       = %q{RSpec custom matchers for ftp server.}
  spec.description   = %q{RSpec custom matchers for ftp server.}
  spec.homepage      = "https://github.com/suzuki86/ftpspec"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = "ftpspec-init"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
