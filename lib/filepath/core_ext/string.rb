# This is free software released into the public domain (CC0 license).


class String
	# Generates a path from a String.
	#
	# `"/a/b/c".as_path` is equivalent to `Filepath.new("/a/b/c")`.
	#
	# @example Filepath from a string
	#
	#     "/etc/ssl/certs".as_path #=> </etc/ssl/certs>
	#
	# @return [Filepath] a new path generated from the string
	#
	# @note FIXME: `#as_path` should be `#to_path` but that method name
	#       is already used

	def as_path
		Filepath.new(self)
	end
end
