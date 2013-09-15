# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
	spec.name          = "filepath"
	spec.version       = "0.6"
	spec.authors       = ["Gioele Barabucci"]
	spec.email         = ["gioele@svario.it"]
	spec.summary       = "filepath is a small library that helps dealing with files, " +
	                     "directories and paths in general; a modern replacement for " +
			     "the standard Pathname."
	spec.description   = "filepath is built around two main classes: `FilePath`, that " +
	                     "represents paths, and `FilePathList`, lists of paths. The " +
			     "instances of these classes are immutable objects with dozens " +
			     "of convience methods for common operations such as calculating " +
			     "relative paths, concatenating paths, finding all the files in " +
			     "a directory or modifing all the extensions of a list of file "
			     "names at once."
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
