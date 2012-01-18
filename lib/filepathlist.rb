# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

class FilePathList
	include Enumerable

	SEPARATOR = ':'.freeze

	def initialize(raw_entries = nil)
		raw_entries ||= []
		@entries = raw_entries.map { |e| FilePath.new(e) }
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

	def exclude(pattern) # FIXME: block
		raw_entries = @entries.delete_if { |e| e =~ pattern }
		return FilePathList.new(raw_entries)
	end

	def /(extra_path)
		return self.map { |path| path / extra_path }
	end

	def +(extra_entries)
		return FilePathList.new(@entries + extra_entries.to_a)
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

	def remove_common_fragments
		all_frags = @entries.map(&:fragments)
		max_length = all_frags.map(&:length).min

		idx_different = nil

		(0..max_length).each do |i|
			fragment = all_frags.first[i]

			different = all_frags.any? { |frags| frags[i] != fragment }
			if different
				idx_different = i
				break
			end
		end

		idx_different ||= max_length

		remaining_frags = all_frags.map { |frags| frags[idx_different..-1] }

		return FilePathList.new(remaining_frags)
	end

	def to_a
		@entries
	end

	def to_s
		@to_s ||= @entries.map(&:to_s).join(SEPARATOR)
	end

	def ==(other)
		@entries == other.to_a # FIXME: entries, non-list
	end

	# FIXME: delegate :to => @entries
	def [](index)
		@entries[index]
	end

	def include?(*others)
		@entries.include?(*others)
	end

	def each(&block)
		@entries.each(&block)
	end

	def map(&block)
		@entries.map(&block)
	end

	def inspect
		@entries.inspect
	end
end

class Array
	def as_path_list
		FilePathList.new(self)
	end
end
