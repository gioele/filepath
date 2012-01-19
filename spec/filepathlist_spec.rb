# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

require File.join(File.dirname(__FILE__), 'spec_helper')

describe FilePathList do
	describe "#initialize" do
		it "creates an empty FilePathList" do
			list = FilePathList.new()

			list.should be_empty
		end

		it "creates a FilePathList from an Array of Strings" do
			paths = %w{a/b c/d e/f}
			list = FilePathList.new(paths)

			list.should have(3).items
			list.each { |path| path.should be_a(FilePath) }
		end

		it "creates a FilePathList from an Array of FilePaths" do
			paths = %w{a/b c/d e/f}.map(&:as_path)
			list = FilePathList.new(paths)

			list.should have(3).items
			list.each { |path| path.should be_a(FilePath) }
		end

		it "creates a FilePathList from an Array of Arrays" do
			paths = [%w{a b}, %w{c d}, %w{e f}]
			list = FilePathList.new(paths)

			list.should have(3).items
			list.each { |path| path.should be_a(FilePath) }
		end
	end

	describe "#exclude" do
		list = FilePathList.new(%w{a.foo b.bar c.foo d.foo b.bar})
		refined = list.exclude(/bar$/)
		refined.each { |path| path.extension.should == 'foo' }
	end

	describe "#/" do
		it "adds the same string to all the paths" do
			list = FilePathList.new(%w{foo faa}) / 'bar'
			list[0].should eq 'foo/bar'
			list[1].should eq 'faa/bar'
		end
	end

	describe "#+" do
		it "concatenates two FilePathLists" do
			list1 = FilePathList.new(%w{a b c})
			list2 = FilePathList.new(%w{d e})

			list = list1 + list2
			list.should have(5).items
			list[0].should eq('a')
			list[1].should eq('b')
			list[2].should eq('c')
			list[3].should eq('d')
			list[4].should eq('e')
		end
	end

	describe "#<<" do
		it "adds a new to path to a existing FilePathList" do
			list1 = FilePathList.new(%w{a/b /c/d})
			list2 = list1 << "e/f"

			list1.should have(2).items
			list2.should have(3).items

			list2[0].should eq('a/b')
			list2[1].should eq('/c/d')
			list2[2].should eq('e/f')
		end
	end

	describe "#*" do
		describe "calculates the cartesian product between" do
			it "two FilePathLists" do
				p1 = %w{a b c}
				p2 = %w{1 2}
				list1 = FilePathList.new(p1)
				list2 = FilePathList.new(p2)

				all_paths = p1.product(p2).map { |x| x.join('/') }

				list = list1 * list2
				list.should have(6).items
				list.should include(*all_paths)
			end

			it "a FilePathList and a string" do
				p1 = %w{a b c}
				p2 = "abc"

				list = FilePathList.new(p1) * p2
				list.should have(3).items
				list.should include(*%w{a/abc b/abc c/abc})
			end

			it "a FilePathList and a FilePath" do
				p1 = %w{a b c}
				p2 = FilePath.new("x")

				list = FilePathList.new(p1) * p2
				list.should have(3).items
				list.should include(*%w{a/x b/x c/x})
			end

			it "a FilePath and an array of strings" do
				p1 = %w{a b c}
				p2 = ["1", "2"]

				list = FilePathList.new(p1) * p2
				list.should have(6).items
				list.should include(*%w{a/1 b/1 a/2 b/2 c/1 c/2})
			end
		end
	end

	describe "#remove_common_fragments" do
		it "works on lists of files from the same dir" do
			paths = %w{a/b/x1 a/b/x2 a/b/x3}
			list = FilePathList.new(paths).remove_common_fragments

			list.should have(3).items
			list.should include(*%w{x1 x2 x3})
		end

		it "works on lists of files from different dirs" do
			list1 = FilePathList.new(%w{a/b/x1 a/b/c/x2 a/b/d/e/x3})
			list2 = list1.remove_common_fragments

			list2.should have(3).items
			list2.should include(*%w{x1 c/x2 d/e/x3})
		end

		it "works on lists of files with no common fragments" do
			paths = %w{a/b a/d g/f}
			list1 = FilePathList.new(paths)
			list2 = list1.remove_common_fragments

			list1.should == list2
		end

		it "works on lists that contain duplicates only" do
			paths = %w{a/b a/b a/b}
			list1 = FilePathList.new(paths)
			list2 = list1.remove_common_fragments

			list2.should == FilePathList.new(['.', '.', '.'])
		end
	end

	describe "#include?" do
		it "says that 'a/c' is included in [<a/b>, <a/c>, </a/d>]" do
			list = FilePathList.new(%w{a/b a/c /a/d})
			list.should include("a/c")
		end
	end

	describe "#to_s" do
		it "returns files separated by a comma`" do
			list = FilePathList.new(%w{a/b a/c /a/d})
			list.to_s.should == "a/b:a/c:/a/d"
		end
	end

	describe "#==" do
		let(:list) { ['a/b', 'c/d', 'e/f'].as_path_list }

		it "compares a FilePathList to another FilePathList" do
			list2 = FilePathList.new << 'a/b' << 'c/d' << 'e/f'
			list3 = list2 << 'g/h'

			list.should eq(list2)
			list.should_not eq(list3)
		end

		it "compares a FilePathList to an Array of Strings" do
			list.should eq(%w{a/b c/d e/f})
			list.should_not eq(%w{a/a b/b c/c})
		end
	end
end


describe Array do
	describe "#as_path_list" do
		it "generates a FilePathList from an Array" do
			paths = %w{/a/b c/d /f/g}
			list = paths.as_path_list

			list.should be_a(FilePathList)
			list.should include(*paths)
		end
	end
end
