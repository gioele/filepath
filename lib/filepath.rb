# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

require 'filepathlist'

class FilePath
	SEPARATOR = '/'.freeze

	def initialize(path)
		if path.is_a? FilePath
			@segments = path.segments
		elsif path.is_a? Array
			@segments = path
		else
			@segments = split_path_string(path.to_str)
		end
	end

	attr_reader :segments

	# Creates a FilePath joining the given segments.
	#
	# @return [FilePath] a FilePath created joining the given segments

	def FilePath.join(*raw_paths)
		if (raw_paths.count == 1) && (raw_paths.first.is_a? Array)
			raw_paths = raw_paths.first
		end

		paths = raw_paths.map { |p| p.as_path }

		frags = []
		paths.each { |path| frags += path.segments }

		return FilePath.new(frags)
	end


	# Appends another path to the current path.
	#
	# @example Append a string
	#
	#    "a/b".as_path / "c" #=> <a/b/c>
	#
	# @example Append another FilePath
	#
	#    home = (ENV["HOME"] || "/root").as_path
	#    conf_dir = '.config'.as_path
	#
	#    home / conf_dir #=> </home/user/.config>
	#
	# @param [FilePath, String] extra_path the path to be appended to the
	#                                      current path
	#
	# @return [FilePath] a new path with the given path appended

	def /(extra_path)
		return FilePath.join(self, extra_path)
	end


	# Append multiple paths to the current path.
	#
	# @return [FilePath] a new path with all the paths appended

	def join(*extra_paths)
		return FilePath.join(self, *extra_paths)
	end

	alias :append :join


	# An alias for {FilePath#/}.
	#
	# @deprecated Use the {FilePath#/} (slash) method instead. This method
	#             does not show clearly if a path is being added or if a
	#             string should be added to the filename

	def +(extra_path)
		warn "FilePath#+ is deprecated, use FilePath#/ instead."
		return self / extra_path
	end


	# Calculates the relative path from a given directory.
	#
	# @example relative paths between relative paths
	#
	#     posts_dir = "posts".as_path
	#     images_dir = "static/images".as_path
	#
	#     logo = images_dir / 'logo.png'
	#
	#     logo.relative_to(posts_dir) #=> <../static/images/logo.png>
	#
	# @example relative paths between absolute paths
	#
	#     home_dir = "/home/gioele".as_path
	#     docs_dir = "/home/gioele/Documents".as_path
	#     tmp_dir = "/tmp".as_path
	#
	#     docs_dir.relative_to(home_dir) #=> <Documents>
	#     home_dir.relative_to(docs_dir) #=> <..>
	#
	#     tmp_dir.relative_to(home_dir) #=> <../../tmp>
	#
	# @param [FilePath, String] base the directory to use as base for the
	#                                relative path
	#
	# @return [FilePath] the relative path
	#
	# @note this method operates on the normalized paths
	#
	# @see #relative_to_file

	def relative_to(base)
		base = base.as_path

		if self.absolute? != base.absolute?
			self_abs = self.absolute? ? "absolute" : "relative"
			base_abs = base.absolute? ? "absolute" : "relative"
			msg = "cannot compare: "
			msg += "`#{self}` is #{self_abs} while "
			msg += "`#{base}` is #{base_abs}"
			raise ArgumentError, msg
		end

		self_frags = self.normalized_segments
		base_frags = base.normalized_segments

		base_frags_tmp = base_frags.dup
		num_same = self_frags.find_index do |frag|
			base_frags_tmp.delete_at(0) != frag
		end

		# find_index returns nil if `self` is a subset of `base`
		num_same ||= self_frags.length

		num_parent_dirs = base_frags.length - num_same
		left_in_self = self_frags[num_same..-1]

		frags = [".."] * num_parent_dirs + left_in_self
		normalized_frags = normalized_relative_frags(frags)

		return FilePath.join(normalized_frags)
	end

	# Calculates the relative path from a given file.
	#
	# @example relative paths between relative paths
	#
	#     post = "posts/2012-02-14-hello.html".as_path
	#     images_dir = "static/images".as_path
	#
	#     rel_img_dir = images_dir.relative_to_file(post)
	#     rel_img_dir.to_s #=> "../static/images"
	#
	#     logo = rel_img_dir / 'logo.png' #=> <../static/images/logo.png>
	#
	# @example relative paths between absolute paths
	#
	#     rc_file = "/home/gioele/.bashrc".as_path
	#     tmp_dir = "/tmp".as_path
	#
	#     tmp_dir.relative_to_file(rc_file) #=> <../../tmp>
	#
	# @param [FilePath, String] base the file to use as base for the
	#                                relative path
	#
	# @return [FilePath] the relative path
	#
	# @see #relative_to

	def relative_to_file(base_file)
		return relative_to(base_file.as_path.parent_dir)
	end


	# The filename component of the path.
	#
	# The filename is the component of a path that appears after the last
	# path separator.
	#
	# @return [FilePath] the filename

	def filename
		if self.root?
			return ''.as_path
		end

		filename = self.normalized_segments.last
		return filename.as_path
	end

	alias :basename :filename


	# The dir that contains the file
	#
	# @return [FilePath] the path of the parent dir

	def parent_dir
		return self / '..'
	end


	# Replace the path filename with the supplied path.
	#
	# @example
	#
	#     post = "posts/2012-02-16-hello-world/index.md".as_path
	#     style = post.replace_filename("style.css")
	#     style.to_s #=> "posts/2012-02-16-hello-world/style.css"
	#
	# @param [FilePath, String] new_path the path to be put in place of
	#                                    the current filename
	#
	# @return [FilePath] a path with the supplied path instead of the
	#                    current filename
	#
	# @see #filename
	# @see #replace_extension

	def replace_filename(new_path)
		dir = self.parent_dir
		return dir / new_path
	end

	alias :replace_basename :replace_filename


	# The extension of the file.
	#
	# The extension of a file are the characters after the last dot.
	#
	# @return [String] the extension of the file or nil if the file has no
	#                  extension
	#
	# @see #extension?

	def extension
		filename = @segments.last

		num_dots = filename.count('.')

		if num_dots.zero?
			ext = nil
		elsif filename.start_with?('.') && num_dots == 1
			ext = nil
		elsif filename.end_with?('.')
			ext = ''
		else
			ext = filename.split('.').last
		end

		return ext
	end

	alias :ext :extension


	# @overload extension?(ext)
	#     @param [String, Regexp] ext the extension to be matched
	#
	#     @return whether the file extension matches the given extension
	#
	# @overload extension?
	#     @return whether the file has an extension

	def extension?(ext = nil)
		cur_ext = self.extension

		if ext.nil?
			return !cur_ext.nil?
		else
			if ext.is_a? Regexp
				return !cur_ext.match(ext).nil?
			else
				return cur_ext == ext
			end
		end
	end

	alias :ext? :extension?


	# Replaces or removes the file extension.
	#
	# @see #extension
	# @see #extension?
	# @see #remove_extension
	# @see #replace_filename
	#
	# @overload replace_extension(new_ext)
	#     Replaces the file extension with the supplied one. If the file
	#     has no extension it is added to the file name together with a dot.
	#
	#     @example Extension replacement
	#
	#         src_path = "pages/about.markdown".as_path
	#         html_path = src_path.replace_extension("html")
	#         html_path.to_s #=> "pages/about.html"
	#
	#     @example Extension addition
	#
	#         base = "style/main-style".as_path
	#         sass_style = base.replace_extension("sass")
	#         sass_style.to_s #=> "style/main-style.sass"
	#
	#     @param [String] new_ext the new extension
	#
	#     @return [FilePath] a new path with the replaced extension
	#
	# @overload replace_extension
	#     Removes the file extension if present.
	#
	#     The {#remove_extension} method provides the same functionality
	#     but has a more meaningful name.
	#
	#     @example
	#
	#         post_file = "post/welcome.html"
	#         post_url = post_file.replace_extension(nil)
	#         post_url.to_s #=> "post/welcome"
	#
	#     @return [FilePath] a new path without the extension

	def replace_extension(new_ext) # FIXME: accept block
		orig_filename = filename.to_s

		if !self.extension?
			if new_ext.nil?
				new_filename = orig_filename
			else
				new_filename = orig_filename + '.' + new_ext
			end
		else
			if new_ext.nil?
				pattern = /\.[^.]*?\Z/
				new_filename = orig_filename.sub(pattern, '')
			else
				pattern = Regexp.new('.' + extension + '\\Z')
				new_filename = orig_filename.sub(pattern, '.' + new_ext)
			end
		end

		frags = @segments[0..-2]
		frags << new_filename

		return FilePath.new(frags)
	end

	alias :replace_ext :replace_extension
	alias :sub_ext :replace_extension


	# Removes the file extension if present.
	#
	# @example
	#
	#     post_file = "post/welcome.html"
	#     post_url = post_file.remove_extension
	#     post_url.to_s #=> "post/welcome"
	#
	# @return [FilePath] a new path without the extension
	#
	# @see #replace_extension

	def remove_extension
		return replace_ext(nil)
	end

	alias :remove_ext :remove_extension


	# Matches a pattern against this path.
	#
	# @param [Regexp, Object] pattern the pattern to match against
	#                                 this path
	#
	# @return [Fixnum, nil] the position of the pattern in the path, or
	#                       nil if there is no match
	#
	# @note this method operates on the normalized path

	def =~(pattern)
		return self.to_s =~ pattern
	end

	def root?
		return @segments == [SEPARATOR] # FIXME: windows, mac
	end


	# Is this path absolute?
	#
	# @example
	#
	#     "/tmp".absolute?   #=> true
	#     "tmp".absolute?    #=> false
	#     "../tmp".absolute? #=> false
	#
	# FIXME: document what an absolute path is.
	#
	# @return whether the current path is absolute
	#
	# @see #relative?

	def absolute?
		return @segments.first == SEPARATOR # FIXME: windows, mac
	end


	# Is this path relative?
	#
	# @example
	#
	#     "/tmp".relative?   #=> false
	#     "tmp".relative?    #=> true
	#     "../tmp".relative? #=> true
	#
	# FIXME: document what a relative path is.
	#
	# @return whether the current path is relative
	#
	# @see #absolute?

	def relative?
		return !self.absolute?
	end


	# Simplify paths that contain `.` and `..`.
	#
	# The resulting path will be in normal form.
	#
	# @example
	#
	#     path = $ENV["HOME"] / ".." / "jack" / "."
	#
	#     path #=> </home/gioele/../jack/.>
	#     path.normalized #=> </home/jack>
	#
	# FIXME: document what normal form is.
	#
	# @return [FilePath] a new path that does not contain `.` or `..`
	#                    segments.

	def normalized
		return FilePath.join(self.normalized_segments)
	end

	alias :normalised :normalized


	# Iterates over all the path directories, from the current path to
	# the root.
	#
	# @example
	#
	#     web_dir = "/srv/example.org/web/html/".as_path
	#     web_dir.ascend do |path|
	#         is = path.readable? ? "is" : "is NOT"
	#
	#         puts "#{path} #{is} readable"
	#     end
	#
	#     # produces
	#     #
	#     # /srv/example.org/web/html is NOT redable
	#     # /srv/example.org/web is NOT readable
	#     # /srv/example.org is readable
	#     # /srv is readable
	#     # / is readable
	#
	# @param max_depth the maximum depth to ascend to, nil to ascend
	#                  without limits.
	#
	# @yield [path] TODO
	#
	# @return [FilePath] the path itself.
	#
	# @see #descend

	def ascend(max_depth = nil, &block)
		iterate(max_depth, :reverse_each, &block)
	end


	# Iterates over all the directory that lead to the current path.
	#
	# @example
	#
	#     web_dir = "/srv/example.org/web/html/".as_path
	#     web_dir.descend do |path|
	#         is = path.readable? ? "is" : "is NOT"
	#
	#         puts "#{path} #{is} readable"
	#     end
	#
	#     # produces
	#     #
	#     # / is readable
	#     # /srv is readable
	#     # /srv/example.org is readable
	#     # /srv/example.org/web is NOT readable
	#     # /srv/example.org/web/html is NOT redable
	#
	# @param max_depth the maximum depth to descent to, nil to descend
	#                  without limits.
	#
	# @yield [path] TODO
	#
	# @return [FilePath] the path itself.
	#
	# @see #ascend

	def descend(max_depth = nil, &block)
		iterate(max_depth, :each, &block)
	end


	# @private
	def iterate(max_depth, method, &block)
		max_depth ||= @segments.length
		(1..max_depth).send(method) do |limit|
			frags = @segments.take(limit)
			yield FilePath.join(frags)
		end

		return self
	end


	# This path converted to a String.
	#
	# @example differences between #to_raw_string and #to_s
	#
	#    path = "/home/gioele/.config".as_path / ".." / ".cache"
	#    path.to_raw_string #=> "/home/gioele/config/../.cache"
	#    path.to_s #=> "/home/gioele/.cache"
	#
	# @return [String] this path converted to a String
	#
	# @see #to_s

	def to_raw_string
		@to_raw_string ||= join_segments(@segments)
	end

	alias :to_raw_str :to_raw_string


	# @return [String] this path converted to a String
	#
	# @note this method operates on the normalized path

	def to_s
		to_str
	end


	def to_str
		@to_str ||= join_segments(self.normalized_segments)
	end


	# @return [FilePath] the path itself.
	def as_path
		self
	end


	def inspect
		return '<' +  self.to_raw_string + '>'
	end

	def ==(other)
		return self.normalized_segments == other.as_path.normalized_segments
	end

	def eql?(other)
		if self.equal?(other)
			return true
		elsif self.class != other.class
			return false
		end

		return @segments == other.segments
	end

	def hash
		return @segments.hash
	end

	# @private
	def split_path_string(raw_path)
		segments = raw_path.split(SEPARATOR) # FIXME: windows, mac

		if raw_path == SEPARATOR
			segments << SEPARATOR
		end

		if !segments.empty? && segments.first.empty?
			segments[0] = SEPARATOR
		end

		return segments
	end

	# @private
	def normalized_segments
		@normalized_segments ||= normalized_relative_frags(@segments)
	end

	# @private
	def normalized_relative_frags(orig_frags)
		frags = orig_frags.dup

		# remove "current dir" markers
		frags.delete('.')

		i = 0
		while (i < frags.length)
			if frags[i] == '..' && frags[i-1] == SEPARATOR
				# remove '..' segments following a root delimiter
				frags.delete_at(i)
				i -= 1
			elsif frags[i] == '..' && frags[i-1] != '..' && i >= 1
				# remove every segment followed by a ".." marker
				frags.delete_at(i)
				frags.delete_at(i-1)
				i -= 2
			end
			i += 1
		end

		return frags
	end

	# @private
	def join_segments(frags)
		# FIXME: windows, mac
		# FIXME: avoid string substitutions and regexen
		return frags.join(SEPARATOR).sub(%r{^//}, SEPARATOR).sub(/\A\Z/, '.')
	end

	module PathResolution
		def absolute_path(base_dir = Dir.pwd) # FIXME: rename to `#absolute`?
			if self.absolute?
				return self
			end

			return base_dir.as_path / self
		end

		def real_path(base_dir = Dir.pwd)
			path = absolute_path(base_dir)

			return path.resolve_link
		end

		alias :realpath :real_path

		def resolve_link
			return File.readlink(self).as_path
		end
	end

	module FileInfo
		# @private
		def self.define_filetest_method(filepath_method, filetest_method = nil)
			filetest_method ||= filepath_method
			define_method(filepath_method) do
				return FileTest.send(filetest_method, self)
			end
		end

		define_filetest_method :file?

		define_filetest_method :link?, :symlink?
		alias :symlink? :link?

		define_filetest_method :directory?

		define_filetest_method :exists?
		alias :exist? :exists?

		define_filetest_method :readable?

		define_filetest_method :writeable?

		define_filetest_method :executable?

		define_filetest_method :setgid?

		define_filetest_method :setuid?

		define_filetest_method :empty?, :zero?
		alias :zero? :empty?

		def hidden?
			@segments.last.start_with?('.') # FIXME: windows, mac
		end
	end

	module FileManipulationMethods
		def open(*args, &block)
			File.open(self, *args, &block)
		end

		def touch
			self.open('a') do ; end
			File.utime(File.atime(self), Time.now, self)
		end
	end

	module DirectoryMethods
		def entries(pattern = '*', recursive = false)
			if !self.directory?
				raise Errno::ENOTDIR.new(self)
			end

			glob = self
			glob /= '**' if recursive
			glob /= pattern

			raw_entries = Dir.glob(glob)
			entries = FilePathList.new(raw_entries)

			return entries
		end
		alias :glob :entries

		def find(pattern = nil, &block)
			if pattern.respond_to? :to_str
				return entries(pattern, true)
			end

			if !block_given?
				block = proc { |e| e =~ pattern }
			end

			return entries('*', true).select { |e| block.call(e) }
		end

		def files(recursive = false)
			entries('*', recursive).select_entries(:file)
		end

		def links(recursive = false)
			entries('*', recursive).select_entries(:link)
		end

		def directories(recursive = false)
			entries('*', recursive).select_entries(:directory)
		end
	end

	include PathResolution
	include FileInfo
	include FileManipulationMethods
	include DirectoryMethods
end

class String
	# Generates a path from a String.
	#
	# `"/a/b/c".as_path` is equivalent to `FilePath.new("/a/b/c")`.
	#
	# @example FilePath from a string
	#
	#     "/etc/ssl/certs".as_path #=> </etc/ssl/certs>
	#
	# @return [FilePath] a new path generated from the string
	#
	# @note FIXME: `#as_path` should be `#to_path` but that method name
	#       is already used
	def as_path
		FilePath.new(self)
	end
end

class Array
	# Generates a path using the elements of an array as path segments.
	#
	# `[a, b, c].as_path` is equivalent to `FilePath.join(a, b, c)`.
	#
	# @example FilePath from an array of strings
	#
	#     ["/", "foo", "bar"].as_path #=> </foo/bar>
	#
	# @example FilePath from an array of strings and other FilePaths
	#
	#     server_dir = config["root_dir"] / "server"
	#     ["..", config_dir, "secret"].as_path #=> <../config/server/secret>
	#
	# @return [FilePath] a new path generated using the element as path
	#         segments
	#
	# @note FIXME: `#as_path` should be `#to_path` but that method name
	#       is already used
	def as_path
		FilePath.join(self)
	end
end
