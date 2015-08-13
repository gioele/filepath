# This is free software released into the public domain (CC0 license).

require File.join(File.dirname(__FILE__), 'spec_helper')

describe FilepathList do
	describe "#initialize" do
		it "creates an empty FilepathList" do
			list = FilepathList.new()

			list.should be_empty
		end

		it "creates a FilepathList from an Array of Strings" do
			paths = %w{a/b c/d e/f}
			list = FilepathList.new(paths)

			list.size.should eq(3)
			list.each { |path| path.should be_a(Filepath) }
		end

		it "creates a FilepathList from an Array of Filepaths" do
			paths = %w{a/b c/d e/f}.map(&:as_path)
			list = FilepathList.new(paths)

			list.size.should eq(3)
			list.each { |path| path.should be_a(Filepath) }
		end

		it "creates a FilepathList from an Array of Arrays" do
			paths = [%w{a b}, %w{c d}, %w{e f}]
			list = FilepathList.new(paths)

			list.size.should eq(3)
			list.each { |path| path.should be_a(Filepath) }
		end
	end

	describe "#/" do
		it "adds the same string to all the paths" do
			list = FilepathList.new(%w{foo faa}) / 'bar'
			list[0].should eq 'foo/bar'
			list[1].should eq 'faa/bar'
		end
	end

	describe "#+" do
		it "concatenates two FilepathLists" do
			list1 = FilepathList.new(%w{a b c})
			list2 = FilepathList.new(%w{d e})

			list = list1 + list2
			list.size.should eq(5)
			list[0].should eq('a')
			list[1].should eq('b')
			list[2].should eq('c')
			list[3].should eq('d')
			list[4].should eq('e')
		end
	end

	describe "#-" do
		it "removes a list (as array of strings) from another list" do
			list1 = FilepathList.new(%w{a/b /a/c e/d})
			list2 = list1 - %w{a/b e/d}

			list2.size.should eq(1)
			list2[0].should eq('/a/c')
		end
	end

	describe "#<<" do
		it "adds a new to path to a existing FilepathList" do
			list1 = FilepathList.new(%w{a/b /c/d})
			list2 = list1 << "e/f"

			list1.size.should eq(2)
			list2.size.should eq(3)

			list2[0].should eq('a/b')
			list2[1].should eq('/c/d')
			list2[2].should eq('e/f')
		end
	end

	describe "#*" do
		describe "calculates the cartesian product between" do
			it "two FilepathLists" do
				p1 = %w{a b c}
				p2 = %w{1 2}
				list1 = FilepathList.new(p1)
				list2 = FilepathList.new(p2)

				all_paths = p1.product(p2).map { |x| x.join('/') }

				list = list1 * list2
				list.size.should eq(6)
				list.should include(*all_paths)
			end

			it "a FilepathList and a string" do
				p1 = %w{a b c}
				p2 = "abc"

				list = FilepathList.new(p1) * p2
				list.size.should eq(3)
				list.should include(*%w{a/abc b/abc c/abc})
			end

			it "a FilepathList and a Filepath" do
				p1 = %w{a b c}
				p2 = Filepath.new("x")

				list = FilepathList.new(p1) * p2
				list.size.should eq(3)
				list.should include(*%w{a/x b/x c/x})
			end

			it "a Filepath and an array of strings" do
				p1 = %w{a b c}
				p2 = ["1", "2"]

				list = FilepathList.new(p1) * p2
				list.size.should eq(6)
				list.should include(*%w{a/1 b/1 a/2 b/2 c/1 c/2})
			end
		end
	end

	describe "#remove_common_segments" do
		it "works on lists of files from the same dir" do
			paths = %w{a/b/x1 a/b/x2 a/b/x3}
			list = FilepathList.new(paths).remove_common_segments

			list.size.should eq(3)
			list.should include(*%w{x1 x2 x3})
		end

		it "works on lists of files from different dirs" do
			list1 = FilepathList.new(%w{a/b/x1 a/b/c/x2 a/b/d/e/x3})
			list2 = list1.remove_common_segments

			list2.size.should eq(3)
			list2.should include(*%w{x1 c/x2 d/e/x3})
		end

		it "works on lists of files with no common segments" do
			paths = %w{a/b a/d g/f}
			list1 = FilepathList.new(paths)
			list2 = list1.remove_common_segments

			list1.should == list2
		end

		it "works on lists that contain duplicates only" do
			paths = %w{a/b a/b a/b}
			list1 = FilepathList.new(paths)
			list2 = list1.remove_common_segments

			list2.should == FilepathList.new(['.', '.', '.'])
		end
	end

	describe "#include?" do
		it "says that 'a/c' is included in [<a/b>, <a/c>, </a/d>]" do
			list = FilepathList.new(%w{a/b a/c /a/d})
			list.should include("a/c")
		end
	end

	describe "#to_s" do
		it "returns files separated by a comma`" do
			list = FilepathList.new(%w{a/b a/c /a/d})
			list.to_s.should == "a/b:a/c:/a/d"
		end
	end

	describe "#==" do
		let(:list) { ['a/b', 'c/d', 'e/f'].as_path_list }

		it "compares a FilepathList to another FilepathList" do
			list2 = FilepathList.new << 'a/b' << 'c/d' << 'e/f'
			list3 = list2 << 'g/h'

			list.should eq(list2)
			list.should_not eq(list3)
		end

		it "compares a FilepathList to an Array of Strings" do
			list.should eq(%w{a/b c/d e/f})
			list.should_not eq(%w{a/a b/b c/c})
		end
	end

	describe FilepathList::ArrayMethods do
		let(:list) { FilepathList.new(%w{a.foo b.bar c.foo d.foo b.bar}) }

		describe "#all?" do
			it "checks whether a block applies to a list" do
				ok = list.all? { |path| path.extension? }
				ok.should be true
			end
		end

		describe "#any?" do
			it "check whether a block does not apply to any path" do
				ok = list.any? { |path| path.basename == "a.foo" }
				ok.should be true
			end
		end

		describe "#none?" do
			it "check whether a block does not apply to any path" do
				ok = list.none? { |path| path.absolute? }
				ok.should be true
			end
		end
	end

	describe FilepathList::EntriesMethods do
		let(:list) { FilepathList.new(%w{a.foo b.bar c.foo d.foo b.bar}) }

		describe "#select" do
			it "keeps paths matching a Regex" do
				remaining = list.select(/bar$/)

				remaining.should be_a FilepathList
				remaining.size.should eq(2)
				remaining.each { |path| path.extension.should == 'bar' }
			end

			it "keeps all the paths for which the block returns true" do
				remaining = list.select { |ph| ph.extension?('bar') }

				remaining.size.should eq(2)
				remaining.each { |ph| ph.extension.should == 'bar' }
			end
		end

		describe "#exclude" do
			it "excludes paths matching a Regex" do
				remaining = list.exclude(/bar$/)

				remaining.should be_a FilepathList
				remaining.size.should eq(3)
				remaining.each { |path| path.extension.should == 'foo' }
			end

			it "excludes all the paths for which the block returns true" do
				remaining = list.exclude { |path| path.extension?('bar') }

				remaining.should be_a FilepathList
				remaining.size.should eq(3)
				remaining.each { |path| path.extension.should == 'foo' }
			end
		end

		describe "#map" do
			it "applies a block to each path" do
				mapped = list.map { |path| path.remove_extension }

				mapped.should be_a FilepathList
				mapped.size.should eq(list.size)
				mapped.each { |path| path.extension?.should be false }
			end
		end
	end
end


describe Array do
	describe "#as_path_list" do
		it "generates a FilepathList from an Array" do
			paths = %w{/a/b c/d /f/g}
			list = paths.as_path_list

			list.should be_a(FilepathList)
			list.should include(*paths)
		end
	end
end
