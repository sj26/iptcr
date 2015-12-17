# coding: utf-8
require_relative 'lib/iptcr/version'

Gem::Specification.new do |spec|
  spec.name = "iptcr"
  spec.version = IPTCR::VERSION
  spec.author = "Samuel Cochran"
  spec.email = "sj26@sj26.com"
  spec.summary = "Parse IPTC data"
  spec.description = "Parse IPTC data extracted from an image into rich data types and respecting string encodings"
  spec.homepage = "https://github.com/sj26/iptcr"
  spec.license = "MIT"

  spec.required_ruby_version = "~> 2.1"

  spec.files = Dir["README.md", "LICENSE", "lib/**/*"]
  spec.test_files = Dir["test/**/*"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
