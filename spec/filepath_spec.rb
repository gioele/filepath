# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

require File.join(File.dirname(__FILE__), 'spec_helper')

describe FilePath do
	before(:all) do
		@root = FilePath.new(FIXTURES_DIR)
	end

	it "can be created from a string" do
		FilePath.new("foo").should be_a FilePath
	end

	it "can be created from another FilePath" do
		orig = FilePath.new("foo")
		FilePath.new(orig).should be_a FilePath
	end

	describe "#/" do
		test_data = [
			['foo', 'bar', 'foo/bar'],
			['foo', '.', 'foo'],
			['foo', '..', '.'],
			['foo/bar', 'baz', 'foo/bar/baz'],
			['', 'foo/bar', './foo/bar'],
		]
		test_data.each do |base, extra, result|
			it "concatenates `#{base}` and `#{extra}` (as String) into `#{result}`" do
				p = FilePath.new(base) / extra
				p.should == result
			end
		end

		test_data.each do |base, extra, result|
			it "concatenates `#{base}` and `#{extra}` (as FilePath) into `#{result}`" do
				p = FilePath.new(base) / FilePath.new(extra)
				p.should == result
			end
		end
	end

	describe "#+" do
		it "is deprecated but performs as FilePath#/" do
			p1 = FilePath.new("a")
			p2 = FilePath.new("b")

			p1.should_receive(:warn).with(/is deprecated/)
			(p1 + p2).should == (p1 / p2)
		end
	end

	describe "filename" do
		test_data = [
			['/foo/bar', 'bar'],
			['foo', 'foo'],
			['/', ''],
			['/foo/bar/.', 'bar'],
			['a/b/../c', 'c'],
		]
		test_data.each do |path, result|
			it "says that `#{result}` is the filename of `#{path}`" do
				p = FilePath.new(path)
				p.filename.should == result
			end
		end
	end

	describe "parent_dir" do
		test_data = [
			['/foo/bar', '/foo'],
			['foo', '.'],
			['/', '/'],
			['/foo/bar/.', '/foo'],
			['a/b/../c', 'a'],
		]
		test_data.each do |path, result|
			it "says that `#{result}` is the parent dir of `#{path}`" do
				p = FilePath.new(path)
				p.parent_dir.should == result
			end
		end
	end

	describe "#relative_to" do
		test_data = [
			['/a/b/c', '/a/b', 'c'],
			['/a/b/c', '/a/d', '../b/c'],
			['/a/b/c', '/a/b/c/d', '..'],
			['/a/b/c', '/a/b/c', '.'],
			['a/d', 'a/b/c', '../../d'],
			['a/e/f', 'a/b/c/d', '../../../e/f'],
			['a/c', 'a/b/..', 'c'],
		]
		test_data.each do |path, base, result|
			it "says that `#{path}` relative to `#{base}` is `#{result}`" do
				p = FilePath.new(path)
				p.relative_to(base).should == result
			end
		end

		test_data2 = [
			# FIXME: testare /a/b/c con ../d (bisogna prima rendere assoluto quel path)
			['../e', '/a/b/c'],
			['g', '/a/b/c'],
			['/a/b/c', 'm'],
		]
		test_data2.each do |path, base|
			it "raise an exception because `#{path}` and `#{base}` have different prefixes" do
				p = FilePath.new(path)
				expect { p.relative_to(base) }.to raise_error(ArgumentError)
			end
		end
	end

	describe "#relative_to_file" do
				test_data = [
			['/a/b/c', '/a/d', 'b/c'],
			['/a/b/c', '/a/b/c/d', '.'],
			['/a/b/c', '/a/b/c', 'c'],
			['a/d', 'a/b/c', '../d'],
			['a/e/f', 'a/b/c/d', '../../e/f'],
		]
		test_data.each do |path, base, result|
			it "says that `#{path}` relative to the file `#{base}` is `#{result}`" do
				p = FilePath.new(path)
				p.relative_to_file(base).should == result
			end
		end
	end

	describe "#replace_filename" do
		test_data = [
			['foo/bar', 'quux', 'foo/quux'],
			['foo/baz/..', 'quux', 'quux'],
			['/', 'foo', '/foo'],
		]
		test_data.each do |base, new, result|
			it "changes `#{base}` + `#{new}` into `#{result}`" do
				p = FilePath.new(base)
				p.replace_filename(new).should == result
			end
		end
	end

	describe "#extension" do
		test_data = [
			['foo.bar', 'bar'],
			['foo.', ''],
			['foo', nil],
			['foo.bar/baz.buz', 'buz'],
			['foo.bar/baz', nil],
			['.foo', nil],
			['.foo.conf', 'conf'],
		]
		test_data.each do |path, ext|
			it "says that `#{path}` has extension `#{ext}`" do
				FilePath.new(path).extension.should == ext
			end
		end
	end

	describe "#extension?" do
		with_extension = [
			'foo.bar',
			'foo.',
			'.foo.conf',
		]
		with_extension.each do |path|
			it "says that <#{path}> has an extension" do
				FilePath.new(path).extension?.should be_true
			end
		end

		no_extension = [
			'foo',
			'foo.bar/baz',
			'.foo',
		]
		no_extension.each do |path|
			it "says that <#{path}> has no extension" do
				FilePath.new(path).extension?.should be_false
			end
		end

		extension_data = [
			['foo.bar', 'bar'],
			['/foo/bar.', ''],
			['foo/bar.baz.conf', 'conf'],
			['foo.bar.boom', /oo/],
		]
		extension_data.each do |path, ext|
			it "says that <#{path}> extesions is #{ext.inspect}" do
				FilePath.new(path).extension?(ext).should be_true
			end
		end

		it "says that `foo.bar` extension is not `baz`" do
			FilePath.new('foo.bar').extension?('baz').should be_false
		end
	end

	describe "#replace_extension(String)" do
		test_data = [
			['foo.bar', 'foo.baz'],
			['foo.', 'foo.baz'],
			['foo', 'foo.baz'],
			['foo.bar/baz.buz', 'baz.baz'],
			['foo.bar/baz', 'baz.baz'],
		]
		test_data.each do |path, result|
			it "replaces `#{path}` with `baz` into `#{result}`" do
				new = FilePath.new(path).replace_extension('baz')
				new.basename.to_s.should == result
			end
		end
	end

	describe "#remove_extension" do
		test_data = [
			['foo.bar', 'foo'],
			['foo.', 'foo'],
			['foo', 'foo'],
			['foo.bar/baz.buz', 'baz'],
			['foo.bar/baz', 'baz'],
		]
		test_data.each do |path, result|
			it "turns `#{path}` into `#{result}`" do
				new = FilePath.new(path).remove_extension
				new.basename.to_s.should == result
			end
		end
	end

	describe "=~" do
		it "matches `/foo/bar` with /foo/" do
			FilePath.new('/foo/bar').should =~ /foo/
		end

		it "does not match `/foo/bar` with /baz/" do
			FilePath.new('/foo/bar').should_not =~ /baz/
		end

		it "matches `/foo/bar` with /o\\/ba" do
			FilePath.new('/foo/bar').should =~ /o\/b/
		end

		it "matches `/foo/bar/../quux` with /foo\\/quux/" do
			FilePath.new('/foo/bar/../quux').should =~ /foo\/quux/
		end
	end

	describe "#absolute?" do
		it "says that `/foo/bar` is absolute" do
			FilePath.new('/foo/bar').should be_absolute
		end

		it "sasys that `foo/bar` is not absolute" do
			FilePath.new('foo/bar').should_not be_absolute
		end
	end

	describe "#normalized" do
		test_data = [
			['a', 'a'],
			['a/b/c', 'a/b/c'],
			['a/../c', 'c'],
			['a/b/..', 'a'],
			['../a', '../a'],
			['../../a', '../../a'],
			['../a/..', '..'],
			['/', '/'],
			['/..', '/'],
			['/../../../a', '/a'],
		]
		test_data.each do |path, result|
			it "turns `#{path}` into `#{result}`" do
				FilePath.new(path).normalized.to_raw_string.should == result
			end
		end
	end

	describe "#ascend" do
		it "goes through all the fragments of an absolute path" do
			steps = []
			FilePath.new("/a/b/c").ascend do |p|
				steps << p
			end

			steps.should have(4).items
			steps[0].should eq("/a/b/c")
			steps[1].should eq("/a/b")
			steps[2].should eq("/a")
			steps[3].should eq("/")
		end

		it "goes through all the fragments of a relative path" do
			steps = []
			FilePath.new("a/b/c").ascend do |p|
				steps << p
			end

			steps.should have(3).items
			steps[0].should eq("a/b/c")
			steps[1].should eq("a/b")
			steps[2].should eq("a")
		end
	end

	describe "#descend" do
		it "goes through all the fragments of an absolute path" do
			steps = []
			FilePath.new("/a/b/c").descend do |p|
				steps << p
			end

			steps.should have(4).items
			steps[0].should eq("/")
			steps[1].should eq("/a")
			steps[2].should eq("/a/b")
			steps[3].should eq("/a/b/c")
		end

		it "goes through all the fragments of a relative path" do
			steps = []
			FilePath.new("a/b/c").descend do |p|
				steps << p
			end

			steps.should have(3).items
			steps[0].should eq("a")
			steps[1].should eq("a/b")
			steps[2].should eq("a/b/c")
		end
	end

	describe "#to_s" do
		it "works on computed absolute paths" do
			(FilePath.new('/') / 'a' / 'b').to_s.should eql('/a/b')
		end

		it "works on computed relative paths" do
			(FilePath.new('a') / 'b').to_s.should eql('a/b')
		end

		it "returns normalized paths" do
			FilePath.new("/foo/bar/..").to_s.should eql('/foo')
		end

		it "returns '.' for empty paths" do
			FilePath.new('').to_s.should eql('.')
		end
	end

	describe "#as_path" do
		it "returns the path itself" do
			@root.as_path.should be(@root)
		end
	end

	describe "#==(String)" do
		test_data = [
			['./', '.'],
			['a/../b', 'b'],
			['a/.././b', 'b'],
			['a/./../b', 'b'],
			['./foo', 'foo'],
			['a/./b/c', 'a/b/c'],
			['a/b/.', 'a/b'],
			['a/b/', 'a/b'],
			['../a/../b/c/d/../../e', '../b/e'],
		]
		test_data.each do |ver1, ver2|
			it "says that `#{ver1}` is equivalent to `#{ver2}`" do
				p = FilePath.new(ver1)
				p.should == ver2
			end
		end
	end

	describe "#eql?" do
		it "is always true when an object is compared to itself" do
			ph = 'foo/bar/baz'.as_path

			ph.should eql(ph)
		end

		it "matches two different object representing the same path" do
			p1 = '/foo/bar'.as_path
			p2 = '/foo/bar'.as_path

			p1.should eql(p2)
		end

		it "does not match different objects representing different paths" do
			p1 = '/foo/bar'.as_path
			p2 = '/foo/bar/baz'.as_path

			p1.should_not eql(p2)
		end

		it "does not match objects that are not FilePaths" do
			p1 = '/foo/bar/baz'.as_path
			p2 = '/foo/bar/baz'

			p1.should eq(p2)
			p1.should_not eql(p2)
		end
	end

	describe "#hash" do
		it "has the same value for similar paths" do
			p1 = '/foo/bar'.as_path
			p2 = '/foo/bar'.as_path

			p1.hash.should == p2.hash
		end

		it "has different values for different paths" do
			p1 = '/foo/bar'.as_path
			p2 = 'foo/quuz'.as_path

			p1.hash.should_not == p2.hash
		end

		it "has different values for different paths with same normalized path" do
			p1 = '/foo/bar/..'.as_path
			p2 = '/foo'.as_path

			p1.should eq(p2)
			p1.hash.should_not eq(p2.hash)
		end
	end

	describe FilePath::PathResolution do
		describe "#absolute_path" do
			test_data = [
				['d1/l11', File.expand_path('d1/l11', FIXTURES_DIR), FIXTURES_DIR],
				['/foo/bar', '/foo/bar', '.'],
			]
			test_data.each do |path, abs_path, cwd|
				it "resolves <#{path}> to <#{abs_path}> (in #{cwd})" do
					Dir.chdir(cwd) do # FIXME
						FilePath.new(path).absolute_path.should == abs_path
					end
				end
			end
		end

		describe "#real_path" do
			it "resolves <d1/l11> to </dev/null>" do
				(@root / 'd1' / 'l11').real_path.should == '/dev/null'
			end
		end
	end

	describe FilePath::FileInfo do
		describe "#file?" do
			it "says that `f1` is a file" do
				(@root / 'f1').should be_file
			end

			it "says that `d1/l11` is not a file" do
				(@root / 'd1' / 'l11').should_not be_file
			end

			it "says that the root directory is not a file" do
				@root.should_not be_file
			end
		end

		describe "#link?" do
			it "says that `f1` is not a link" do
				(@root / 'f1').should_not be_link
			end

			it "says that `d1/l11` is a link" do
				(@root / 'd1' / 'l11').should be_link
			end

			it "says that the root directory is not a link" do
				@root.should_not be_link
			end
		end

		describe "#directory?" do
			it "says that `f1` is not a directory" do
				(@root / 'f1').should_not be_directory
			end

			it "says that `d1/l11` is not a directory" do
				(@root / 'd1' / 'l11').should_not be_directory
			end

			it "says that the root directory is file" do
				@root.should be_directory
			end
		end
	end

	describe FilePath::DirectoryMethods do
		describe "#entries" do
			it "raises when path is not a directory" do
				expect { (@root / 'f1').entries(:files) }.to raise_error(Errno::ENOTDIR)
			end
		end

		describe "#files" do
			it "finds 1 file in the root directory" do
				@root.files.should have(1).item
			end

			it "finds 2 files in directory <d1>" do
				(@root / 'd1').files.should have(2).items
			end

			it "finds no files in directory <d1/d12>" do
				(@root / 'd1' / 'd12').files.should have(0).items
			end
		end

		describe "#directories" do
			it "finds 4 directories in the root directory" do
				@root.directories.should have(4).items
			end

			it "finds 2 directories in directory <d2>" do
				(@root / 'd2').directories.should have(2).items
			end

			it "finds no directories in directory <d1/d13>" do
				(@root / 'd1' / 'd13').directories.should have(0).items
			end
		end

		describe "#links" do
			it "finds no links in the root directory" do
				@root.links.should have(0).items
			end

			it "finds 1 link in directory <d1>" do
				(@root / 'd1').links.should have(1).item
			end
		end
	end
end

describe String do
	describe "#as_path" do
		it "generates a FilePath from a String" do
			path = "/a/b/c".as_path
			path.should be_a(FilePath)
			path.should eq("/a/b/c")
		end
	end
end

describe Array do
	describe "#as_path" do
		it "generates a FilePath from a String" do
			path = ['/', 'a', 'b', 'c'].as_path
			path.should be_a(FilePath)
			path.should eq("/a/b/c")
		end
	end
end
