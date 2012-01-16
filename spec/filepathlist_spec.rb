# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

require File.join(File.dirname(__FILE__), 'spec_helper')

describe FilePathList do
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

	describe "#include?" do
		it "says that `a/c` in included in [<a/b>, <a/c>, </a/d>]" do
			list = FilePathList.new(%w{a/b a/c /a/d})
			list.should include("a/c")
		end
	end
end
