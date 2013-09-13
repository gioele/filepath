# This is free software released into the public domain (CC0 license).


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
