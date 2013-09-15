# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
	spec.name          = "filepath"
	spec.version       = "0.7.dev"
	spec.authors       = ["Gioele Barabucci"]
	spec.email         = ["gioele@svario.it"]
	spec.summary       = "A small library to manipulate paths; a modern replacement " +
			     "for the standard Pathname."
	spec.description   = "The Filepath class provides immutable objects with dozens " +
			     "of convenience methods for common operations such as calculating " +
			     "relative paths, concatenating paths, finding all the files in " +
			     "a directory or modifying all the extensions of a list of " +
			     "filenames at once."
	spec.homepage      = "http://github.com/gioele/filepath"
	spec.license       = "CC0"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rake"
	spec.add_development_dependency "rspec"
end
