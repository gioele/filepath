filepath
========

filepath is a small library to manipulate paths; a modern replacement
for the standard Pathname.

filepath is built around two main classes: `Filepath`, that represents paths,
and `FilepathList`, lists of paths. These classes provide immutable objects
with dozens of convenience methods for common operations such as calculating
relative paths, concatenating paths, finding all the files in a directory or
modifying all the extensions of a list of filenames at once.


Features and examples
---------------------

The main purpose of Filepath is to able to write

    require __FILE__.as_path / 'spec' / 'tasks'

instead of cumbersome code like

    require File.join(File.dirname(__FILE__), ['spec', 'tasks'])

The main features of Filepath are…

### Path concatenation

    oauth_conf = ENV['HOME'].as_path / '.config' / 'myapp' / 'oauth.ini'
    oauth_conf.to_s  #=> "/home/gioele/.config/myapp/oauth.ini"

    joe_home = ENV['HOME'].as_path / '..' / 'joe'
    joe_home.to_raw_string #=> "/home/gioele/../joe"
    joe_home.to_s          #=> "/home/joe"

    rel1 = oauth_conf.relative_to(joe_home)
    rel1.to_s #=> "../gioele/.config/myapp/oauth.ini"

    rel2 = joe_home.relative_to(oauth_conf)
    rel2.to_s #=> "../../../joe"

### Path manipulation

    image = ENV['HOME'].as_path / 'Documents' / 'images' / 'cat.png'
    image.parent_dir.to_s  #=> "/home/gioele/Documents/images"
    image.filename.to_s    #=> "cat.png"
    image.extension        #=> "png"

    converted_img = image.replace_extension("jpeg")
    converted_img.to_s     #=> "/home/gioele/Documents/images/cat.jpeg"
    convert(image, converted_img)

### Path traversal

    file_dir = Filepath.new("/srv/example.org/web/html/")
    file_dir.descend do |path|
        is = path.readable? ? "is" : "is not!"

        puts "#{path} #{is} readable"
    end

produces

    / is readable
    /srv is readable
    /srv/example.org is readable
    /srv/example.org/web is not! readable
    /srv/example.org/web/html is not! redable


### Shortcuts for file and directory operations

    home_dir = ENV['HOME']

    files = home_dir.files
    files.count #=> 3
    files.each { |path| puts path.filename.to_s }

produces

    # .bashrc
    # .vimrc
    # TODO.txt

Similarly,

    dirs = home_dir.directories
    dirs.count  #=> 2
    dirs.each { |path| puts path.filename.to_s + "/"}

produces

    # .ssh/
    # Documents/


Requirements
------------

The `filepath` library does not require any external library: it relies
complitely on functionalities available in the Ruby's core classes.

The `filepath` library has been tested and found compatible with Ruby 1.9.3,
Ruby 2.3 and JRuby 9.1.x.x.


Installation
------------

    gem install filepath


Authors
-------

* Gioele Barabucci <http://svario.it/gioele> (initial author)


Development
-----------

Code
: <https://github.com/gioele/filepath>

Report issues
: <https://github.com/gioele/filepath/issues>

Documentation
: <http://rubydoc.info/gems/filepath>


License
-------

This is free software released into the public domain (CC0 license).

See the `COPYING` file or <http://creativecommons.org/publicdomain/zero/1.0/>
for more details.
