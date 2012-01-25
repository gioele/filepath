# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

class FilePathList
	include Enumerable

	SEPARATOR = ':'.freeze

	def initialize(raw_entries = nil)
		raw_entries ||= []
		@entries = raw_entries.map { |e| e.as_path }
	end

	def select_entries(type)
		raw_entries = @entries.delete_if { |e| !e.send(type.to_s + '?') }
		return FilePathList.new(raw_entries)
	end

	def files
		return select_entries(:file)
	end

	def links
		return select_entries(:link)
	end

	def directories
		return select_entries(:directory)
	end

	def /(extra_path)
		return self.map { |path| path / extra_path }
	end

	def +(extra_entries)
		return FilePathList.new(@entries + extra_entries.to_a)
	end

	def -(others)
		remaining_entries = @entries - others.as_path_list.to_a

		return FilePathList.new(remaining_entries)
	end

	def exclude(pattern = nil, &block)
		if block_given?
			select { |e| !block.call(e) }
		else
			select { |e| !(e =~ pattern) }
		end
	end

	def select(pattern = nil, &block)
		if !block_given?
			block = proc { |e| e =~ pattern }
		end

		remaining_entries = @entries.select { |e| block.call(e) }

		return FilePathList.new(remaining_entries)
	end

	def <<(extra_path)
		return FilePathList.new(@entries + [extra_path.as_path])
	end

	def *(other_list)
		if !other_list.is_a? FilePathList
			other_list = FilePathList.new(Array(other_list))
		end
		other_entries = other_list.entries
		paths = @entries.product(other_entries).map { |p1, p2| p1 / p2 }
		return FilePathList.new(paths)
	end

	def remove_common_segments
		all_frags = @entries.map(&:segments)
		max_length = all_frags.map(&:length).min

		idx_different = nil

		(0..max_length).each do |i|
			segment = all_frags.first[i]

			different = all_frags.any? { |frags| frags[i] != segment }
			if different
				idx_different = i
				break
			end
		end

		idx_different ||= max_length

		remaining_frags = all_frags.map { |frags| frags[idx_different..-1] }

		return FilePathList.new(remaining_frags)
	end

	# @return [FilePathList] the path list itself

	def as_path_list
		self
	end

	def to_a
		@entries
	end

	def to_s
		@to_s ||= @entries.map(&:to_str).join(SEPARATOR)
	end

	def inspect
		@entries.inspect
	end

	def ==(other)
		@entries == other.as_path_list.to_a
	end

	module ArrayMethods
		def self.define_array_method(name)
			define_method(name) do |*args, &block|
				return @entries.send(name, *args, &block)
			end
		end

		define_array_method :[]

		define_array_method :empty?

		define_array_method :include?

		define_array_method :each

		define_array_method :map

		define_array_method :size
	end

	include ArrayMethods
end

class Array
	# Generates a path list from an array of paths.
	#
	# The elements of the array must respond to `#as_path`.
	#
	# `ary.as_path` is equivalent to `FilePathList.new(ary)`.
	#
	# @return [FilePathList] a new path list containing the elements of
	#                        the array as FilePaths
	#
	# @see String#as_path
	# @see Array#as_path
	# @see FilePath#as_path

	def as_path_list
		FilePathList.new(self)
	end
end
