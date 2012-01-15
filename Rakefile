# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

begin
	require 'bones'
rescue LoadError
	abort '### Please install the "bones" gem ###'
end

Bones {
	name     'filepath'
	authors  'Gioele Barabucci'
	email    'gioele@svario.it'
	url      'http://github.com/gioele/filepath'

	version  '0.2'

	ignore_file  '.gitignore'

	depend_on 'bones-rspec', :development => true
}

require File.join(File.dirname(__FILE__), 'spec/tasks')

task :default => 'spec:run'
task 'gem:release' => 'spec:run'

task 'spec:run' => 'spec:fixtures:gen'
