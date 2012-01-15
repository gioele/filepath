# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

require 'filepathlist'

class FilePath
	SEPARATOR = '/'.freeze

	def initialize(path)
		if path.is_a? FilePath
			@fragments = path.fragments
		elsif path.is_a? Array
			@fragments = path
		else
			@fragments = split_path_string(path.to_s)
		end
	end

	attr_reader :fragments

	# Creates a FilePath joining the given fragments.
	#
	# @return [FilePath] a FilePath created joining the given fragments

	def FilePath.join(*raw_paths)
		if (raw_paths.count == 1) && (raw_paths.first.is_a? Array)
			raw_paths = raw_paths.first
		end

		paths = raw_paths.map { |p| FilePath.new(p) }

		frags = []
		paths.each { |path| frags += path.fragments }

		return FilePath.new(frags)
	end


	# Appends another path to the current path.
	#
	# @example Append a string
	#
	#    FilePath.new("a/b") / "c" #=> <a/b/c>
	#
	# @example Append another FilePath
	#
	#    home = FilePath.new(ENV["HOME"] || "/root")
	#    conf_dir = FilePath.new('.config')
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


	# Calculates the relative path from another path.
	#
	# @param [FilePath, String] base the path to use as a base for the
	#                                relative path
	#
	# @return [FilePath] the relative path

	def relative_to(base)
		base = FilePath.new(base) unless base.is_a? FilePath

		if self.absolute? != base.absolute?
			self_abs = self.absolute? ? "absolute" : "relative"
			base_abs = base.absolute? ? "absolute" : "relative"
			msg = "cannot compare: "
			msg += "`#{self}` is #{self_abs} while "
			msg += "`#{base}` is #{base_abs}"
			raise msg # FIXME: argerror error class
		end

		self_frags = self.fragments
		base_frags = base.fragments.dup
		num_same = self_frags.find_index do |frag|
			base_frags.delete_at(0) != frag
		end

		# find_index returns nil if `self` is a subset of `base`
		num_same ||= self.fragments.length

		num_parent_dirs = base.fragments.length - num_same
		left_in_self = self.fragments[num_same..-1]

		frags = [".."] * num_parent_dirs + left_in_self

		return FilePath.join(frags)
	end


	# The filename component of the path.
	#
	# The filename is the component of a path that appears after the last
	# path separator.
	#
	# @return [FilePath] the filename

	def filename
		if self.root?
			return FilePath.new('')
		end

		filename = self.normalized_fragments.last
		return FilePath.new(filename)
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
	# @param [FilePath, String] new_path the path to be put in place of
	#                                    the current filename
	#
	# @return [FilePath] a path with the supplied path instead of the
	#                    current filename

	def replace_filename(new_path)
		dir = self.parent_dir
		return dir / FilePath.new(new_path)
	end

	alias :replace_basename :replace_filename


	# The extension of the file.
	#
	# The extension of a file are the characters after the last dot.
	#
	# @return [String] the extension of the file or nil if the file has no
	#                  extension

	def extension
		filename = @fragments.last

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

	alias ext? extension?


	# @overload replace_extension(new_ext)
	#     Replaces the file extension with the supplied one. If the file
	#     has no extension it is added to the file name together with a dot.
	#
	#     @param [String] new_ext the new extension
	#
	#     @return [FilePath] a new path with the replaced extension
	#
	# @overload replace_extension
	#     Removes the file extension if present.
	#
	#     @return [FilePath] a new path without the extension

	def replace_extension(new_ext) # FIXME: accept block
		if !self.extension?
			if new_ext.nil?
				path = self.to_s
			else
				path = self.to_s + '.' + new_ext
			end
		else
			if new_ext.nil?
				pattern = /\.[^.]*?\Z/
				path = self.to_s.sub(pattern, '')
			else
				pattern = '.' + extension
				path = self.to_s.sub(pattern, '.' + new_ext)
			end
		end

		return FilePath.new(path)
	end

	alias :replace_ext :replace_extension
	alias :sub_ext :replace_extension


	# Removes the file extension if present.
	#
	# @return [FilePath] a new path without the extension

	def remove_extension
		return replace_ext(nil)
	end

	alias :remove_ext :remove_extension


	def =~(pattern)
		return self.to_s =~ pattern
	end

	def root?
		return @fragments == [SEPARATOR] # FIXME: windows, mac
	end


	# Is this path absolute?
	#
	# FIXME: document what an absolute path is.
	#
	# @return whether the current path is absolute

	def absolute?
		return @fragments.first == SEPARATOR # FIXME: windows, mac
	end


	# Is this path relative?
	#
	# FIXME: document what a relative path is.
	#
	# @return whether the current path is relative

	def relative?
		return !self.absolute?
	end


	# Simplify paths that contain `.` and `..`.
	#
	# The resulting path will be in normal form.
	#
	# FIXME: document what normal form is.
	#
	# @return [FilePath] a new path that does not contain `.` or `..`
	#                    fragments.

	def normalized
		return FilePath.join(self.normalized_fragments)
	end
	alias :normalised :normalized


	# Iterates over all the path directories, from the current path to
	# the root.
	#
	# @param max_depth the maximum depth to ascend to, nil to ascend
	#                  without limits.
	#
	# @yield [path] TODO

	def ascend(max_depth = nil, &block)
		max_depth ||= @fragments.length
		(1..max_depth).reverse_each do |limit|
			frags = @fragments.take(limit)
			yield FilePath.join(frags)
		end
	end

	# Iterates over all the directory that lead to the current path.
	#
	# @param max_depth the maximum depth to descent to, nil to descend
	#                  without limits.
	#
	# @yield [path] TODO

	def descend(max_depth = nil, &block)
		max_depth ||= @fragments.length
		(1..max_depth).each do |limit|
			frags = @fragments.take(limit)
			yield FilePath.join(frags)
		end
	end


	# This path converted to a String
	#
	# @return [String] this path converted to a String

	def to_raw_string
		return @fragments.join(SEPARATOR).sub(%r{^//}, SEPARATOR) # FIXME: windows, mac
	end

	alias :to_raw_str :to_raw_string


	# @return [String] this path converted to a String
	#
	# @note this method operates on the normalized the path

	def to_s
		return self.normalized_fragments.join(SEPARATOR).sub(%r{^//}, SEPARATOR)
	end


	def inspect
		return '<' +  self.to_raw_string + '>'
	end

	def ==(other)
		return self.to_s == FilePath.new(other).to_s
	end

	# @private
	def split_path_string(raw_path)
		fragments = raw_path.split(SEPARATOR) # FIXME: windows, mac

		if raw_path == SEPARATOR
			fragments << SEPARATOR
		end

		if !fragments.empty? && fragments.first.empty?
			fragments[0] = SEPARATOR
		end

		return fragments
	end

	# @private
	def normalized_fragments
		normalized_relative_frags(self.fragments)
	end

	# @private
	def normalized_relative_frags(orig_frags)
		frags = orig_frags.dup

		# remove "current dir" markers
		frags.delete('.')

		i = 0
		while (i < frags.length)
			if frags[i] == '..' && frags[i-1] == SEPARATOR
				# remove '..' fragments following a root delimiter
				frags.delete_at(i)
				i -= 1
			elsif frags[i] == '..' && frags[i-1] != '..'
				# remove every fragment followed by a ".." marker
				frags.delete_at(i)
				frags.delete_at(i-1)
				i -= 2
			end
			i += 1
		end

		return frags
	end

	module PathResolution
		def absolute_path(base_dir = Dir.pwd) # FIXME: rename to `#absolute`?
			path = if !self.absolute?
				self
			else
				FilePath.new(base_dir) / self
			end

			return path.resolve_link
		end

		def resolve_link
			return FilePath.new(File.readlink(self.to_s))
		end
	end

	module FileInfo
		def file?
			FileTest.file?(self.to_s)
		end

		def link?
			FileTest.symlink?(self.to_s)
		end
		alias symlink? link?

		def directory?
			FileTest.directory?(self.to_s)
		end

		def exists?
			FileTest.exists?(self.to_s)
		end
		alias exist? exists?

		def readable?
			FileTest.readable?(self.to_s)
		end

		def writable?
			FileTest.writable?(self.to_s)
		end

		def executable?
			FileTest.executable?(self.to_s)
		end

		def setgid?
			FileTest.setgid?(self.to_s)
		end

		def setuid?
			FileTest.setuid?(self.to_s)
		end

		def hidden?
			@fragments.last.start_with('.') # FIXME: windows, mac
		end

		def empty?
			FileTest.zero?(self.to_s)
		end
	end

	module FileManipulationMethods
		def open(*args, &block)
			File.open(self.to_s, *args, &block)
		end

		def touch
			self.open do ; end
		end
	end

	module DirectoryMethods
		def entries(pattern = '*')
			if !self.directory?
				raise Errno::ENOTDIR.new(self.to_s)
			end

			raw_entries = Dir.glob((self / pattern).to_s)
			entries = FilePathList.new(raw_entries)

			return entries
		end
		alias :glob :entries

		def files
			entries.select_entries(:file)
		end

		def links
			entries.select_entries(:link)
		end

		def directories
			entries.select_entries(:directory)
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
	# @return [FilePath] a new path generated from the string
	#
	# @note FIXME: `#as_path` should be `#to_path` but that method name
	#       is already used
	def as_path
		FilePath.new(self)
	end
end

class Array
	# Generates a path using the elements of an Array as path fragments.
	#
	# `%w{a b c}.as_path` is equivalent to `FilePath.join('a', 'b', 'c')`.
	#
	# @return [FilePath] a new path generated using the element as path
	#         fragments
	#
	# @note FIXME: `#as_path` should be `#to_path` but that method name
	#       is already used
	def as_path
		FilePath.join(self)
	end
end
