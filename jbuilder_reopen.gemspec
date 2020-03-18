# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jbuilder_reopen/version'

Gem::Specification.new do |spec|
  spec.name          = "jbuilder-reopen"
  spec.version       = JbuilderReopen::VERSION
  spec.authors       = ["Ben Zhang", "Jason Tian"]
  spec.email         = ["jason.tian@pixelforcesystems.com.au"]
  spec.summary       = "Now you can reopen blocks and add additional fields"
  spec.homepage      = "https://www.github.com/jialitian/jbuilder-reopen"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- test/*`.split("\n")

  spec.required_ruby_version = '>= 2.2.2'

  spec.add_dependency 'jbuilder', '~> 2.10'
end
