# This is free software released into the public domain (CC0 license).

require File.join(File.dirname(__FILE__), 'spec_helper')

describe Filepath do
	before(:all) do
		@root = Filepath.new(FIXTURES_DIR)
	end

	it "can be created from a string" do
		Filepath.new("foo").should be_a Filepath
	end

	it "can be created from another Filepath" do
		orig = Filepath.new("foo")
		Filepath.new(orig).should be_a Filepath
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
				ph = Filepath.new(base) / extra
				ph.should == result
			end
		end

		test_data.each do |base, extra, result|
			it "concatenates `#{base}` and `#{extra}` (as Filepath) into `#{result}`" do
				ph = Filepath.new(base) / Filepath.new(extra)
				ph.should == result
			end
		end
	end

	describe "#+" do
		it "is deprecated but performs as Filepath#/" do
			p1 = Filepath.new("a")
			p2 = Filepath.new("b")

			p1.should_receive(:warn).with(/is deprecated/)
			(p1 + p2).should == (p1 / p2)
		end
	end

	describe "#join" do
		test_data = [
			['', ['bar'], './bar'],
			['foo/quux', ['bar', 'baz'], 'foo/quux/bar/baz'],
			['/', ['a', 'b', 'c'], '/a/b/c'],
		]
		test_data.each do |base, extra, result|
			args = extra.map { |x| x.inspect }.join(',')
			it "appends #{args} to '#{base}' to get <#{result}>" do
				base.as_path.join(*extra).should == result
			end
		end
	end

	describe "filename" do
		test_data = [
			['/foo/bar', 'bar'],
			['foo', 'foo'],
			['/', ''],
			['a/b/../../', ''],
			['/foo/bar/.', 'bar'],
			['a/b/../c', 'c'],
		]
		test_data.each do |path, result|
			it "says that `#{result}` is the filename of `#{path}`" do
				ph = Filepath.new(path)
				ph.filename.should == result
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
				ph = Filepath.new(path)
				ph.parent_dir.should == result
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
				ph = Filepath.new(path)
				ph.relative_to(base).should == result
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
				ph = Filepath.new(path)
				expect { ph.relative_to(base) }.to raise_error(ArgumentError)
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
				ph = Filepath.new(path)
				ph.relative_to_file(base).should == result
			end
		end
	end

	describe "#with_filename" do
		test_data = [
			['foo/bar', 'quux', 'foo/quux'],
			['foo/baz/..', 'quux', 'quux'],
			['/', 'foo', '/foo'],
		]
		test_data.each do |base, new, result|
			it "changes `#{base}` + `#{new}` into `#{result}`" do
				ph = Filepath.new(base)
				ph.with_filename(new).should == result
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
				Filepath.new(path).extension.should == ext
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
				Filepath.new(path).extension?.should be true
			end
		end

		no_extension = [
			'foo',
			'foo.bar/baz',
			'.foo',
		]
		no_extension.each do |path|
			it "says that <#{path}> has no extension" do
				Filepath.new(path).extension?.should be false
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
				Filepath.new(path).extension?(ext).should be true
			end
		end

		it "says that `foo.bar` extension is not `baz`" do
			Filepath.new('foo.bar').extension?('baz').should be false
		end
	end

	describe "#with_extension(String)" do
		test_data = [
			['foo.bar', 'foo.baz'],
			['foo.', 'foo.baz'],
			['foo', 'foo.baz'],
			['foo.bar/baz.buz', 'baz.baz'],
			['foo.bar/baz', 'baz.baz'],
		]
		test_data.each do |path, result|
			it "replaces `#{path}` with `baz` into `#{result}`" do
				new = Filepath.new(path).with_extension('baz')
				new.basename.to_s.should == result
			end
		end
	end

	describe "#without_extension" do
		test_data = [
			['foo.bar', 'foo'],
			['foo.', 'foo'],
			['foo', 'foo'],
			['foo.bar/baz.buz', 'baz'],
			['foo.bar/baz', 'baz'],
		]
		test_data.each do |path, result|
			it "turns `#{path}` into `#{result}`" do
				new = Filepath.new(path).without_extension
				new.basename.to_s.should == result
			end
		end
	end

	describe "#add_extension" do
		test_data = [
			['foo', 'e1', 'foo.e1'],
			['foo.e1', 'e2', 'foo.e1.e2'],
			['foo.e1.e2', 'e3', 'foo.e1.e2.e3'],
		]
		test_data.each do |path, ext, result|
			it "turns `#{path}` with `#{ext}` into `#{result}`" do
				new = Filepath.new(path).add_extension(ext)
				new.basename.to_s.should == result
			end
		end
	end

	describe "=~" do
		it "matches `/foo/bar` with /foo/" do
			Filepath.new('/foo/bar').should =~ /foo/
		end

		it "does not match `/foo/bar` with /baz/" do
			Filepath.new('/foo/bar').should_not =~ /baz/
		end

		it "matches `/foo/bar` with /o\\/ba" do
			Filepath.new('/foo/bar').should =~ /o\/b/
		end

		it "matches `/foo/bar/../quux` with /foo\\/quux/" do
			Filepath.new('/foo/bar/../quux').should =~ /foo\/quux/
		end
	end

	describe "#root?" do
		it "says that </> points to the root directory" do
			Filepath.new('/').should be_root
		end

		it "says that </..> points to the root directory" do
			Filepath.new('/..').should be_root
		end

		it "says that <a/b> does not point to the root directory" do
			Filepath.new('a/b').should_not be_root
		end

		it "says that </foo> does not point to the root directory" do
			Filepath.new('/foo/bar').should_not be_root
		end
	end

	describe "#absolute?" do
		it "says that `/foo/bar` is absolute" do
			Filepath.new('/foo/bar').should be_absolute
		end

		it "sasys that `foo/bar` is not absolute" do
			Filepath.new('foo/bar').should_not be_absolute
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
			['a/b/../..', '.'],
		]
		test_data.each do |path, result|
			it "turns `#{path}` into `#{result}`" do
				Filepath.new(path).normalized.to_raw_string.should == result
			end
		end
	end

	describe "#expanded_tilde" do
		it "expands the tilde to the user home directory" do
			home = ENV['HOME']
			ENV['HOME'] = '/home/mel'
			path = "~/.config".as_path
			path_expanded = path.expanded_tilde
			ENV['HOME'] = home

			path_expanded.should eq("/home/mel/.config")
		end
	end

	describe "#each_segment" do
		it "goes through all the segments of an absolute path" do
			steps = []
			Filepath.new("/a/b/c").each_segment do |seg|
				steps << seg
			end

			steps.should have(4).items
			steps[0].should eq("/")
			steps[1].should eq("a")
			steps[2].should eq("b")
			steps[3].should eq("c")
		end

		it "goes through all the segments of a relative path" do
			steps = []
			Filepath.new("a/b/c").each_segment do |seg|
				steps << seg
			end

			steps.should have(3).items
			steps[0].should eq("a")
			steps[1].should eq("b")
			steps[2].should eq("c")
		end

		it "returns the path itself" do
			path = Filepath.new("/a/b/c/")
			path.each_segment { }.should be(path)
		end
	end

	describe "#ascend" do
		it "goes through all the segments of an absolute path" do
			steps = []
			Filepath.new("/a/b/c").ascend do |seg|
				steps << seg
			end

			steps.should have(4).items
			steps[0].should eq("/a/b/c")
			steps[1].should eq("/a/b")
			steps[2].should eq("/a")
			steps[3].should eq("/")
		end

		it "goes through all the segments of a relative path" do
			steps = []
			Filepath.new("a/b/c").ascend do |seg|
				steps << seg
			end

			steps.should have(3).items
			steps[0].should eq("a/b/c")
			steps[1].should eq("a/b")
			steps[2].should eq("a")
		end

		it "returns the path itself" do
			path = Filepath.new("/a/b/c/")
			path.ascend { }.should be(path)
		end
	end

	describe "#descend" do
		it "goes through all the segments of an absolute path" do
			steps = []
			Filepath.new("/a/b/c").descend do |seg|
				steps << seg
			end

			steps.should have(4).items
			steps[0].should eq("/")
			steps[1].should eq("/a")
			steps[2].should eq("/a/b")
			steps[3].should eq("/a/b/c")
		end

		it "goes through all the segments of a relative path" do
			steps = []
			Filepath.new("a/b/c").descend do |seg|
				steps << seg
			end

			steps.should have(3).items
			steps[0].should eq("a")
			steps[1].should eq("a/b")
			steps[2].should eq("a/b/c")
		end

		it "returns the path itself" do
			path = Filepath.new("/a/b/c/")
			path.descend { }.should be(path)
		end
	end

	describe "#to_s" do
		it "works on computed absolute paths" do
			(Filepath.new('/') / 'a' / 'b').to_s.should eql('/a/b')
		end

		it "works on computed relative paths" do
			(Filepath.new('a') / 'b').to_s.should eql('a/b')
		end

		it "returns normalized paths" do
			Filepath.new("/foo/bar/..").to_s.should eql('/foo')
		end

		it "returns '.' for empty paths" do
			Filepath.new('').to_s.should eql('.')
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
				ph = Filepath.new(ver1)
				ph.should == ver2
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

		it "does not match objects that are not Filepaths" do
			p1 = '/foo/bar/baz'.as_path
			p2 = '/foo/bar/baz'

			p1.should eq(p2)
			p1.should_not eql(p2)
		end
	end

	describe "#<=>" do
		test_data = [
			['a/', 'b'],
			['/a', 'a'],
			['../b', 'a'],
		]
		test_data.each do |path1, path2|
			it "says that `#{path1}` precedes `#{path2}`" do
				p1 = path1.as_path
				p2 = path2.as_path

				order = p1 <=> p2
				order.should == -1
			end
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

	describe Filepath::MetadataInfo do
		describe "#stat" do
			it "returns a stat for the file" do
				(@root / 'd1').stat.should be_directory
				(@root / 'f1').stat.size.should be_zero
			end

			it "follows links" do
				(@root / 'd1' / 'l11').stat.should == '/dev/null'.as_path.stat
			end

			it "raises Errno::ENOENT for non-existing files" do
				expect { (@root / 'foobar').stat }.to raise_error(Errno::ENOENT)
			end
		end

		describe "#lstat" do
			it "does not follow links" do
				link_lstat = (@root / 'd1' / 'l11').lstat

				link_lstat.should_not eq('/dev/null'.as_path.stat)
				link_lstat.should be_symlink
			end
		end
	end

	describe Filepath::MetadataChanges do
		describe "#chtime" do
			it "change mtime" do
				ph = @root / 'f1'
				orig_mtime = ph.mtime

				ph.chtime(Time.now, 0)
				ph.mtime.to_i.should eq(0)

				ph.chtime(Time.now, orig_mtime)
				ph.mtime.should eq(orig_mtime)
			end
		end

		describe "#chmod" do
			it "changes file permissions" do
				ph = @root / 'f1'
				orig_mode = ph.stat.mode

				ph.should be_readable

				ph.chmod(000)
				ph.should_not be_readable

				ph.chmod(orig_mode)
				ph.should be_readable
			end
		end
	end

	describe Filepath::MetadataTests do
		describe "#file?" do
			it "says that `f1` is a file" do
				(@root / 'f1').should be_file
			end

			it "says that `d1/l11` is not a file" do
				(@root / 'd1' / 'l11').should_not be_file
			end

			it "says that the fixture root directory is not a file" do
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

			it "says that the fixture root directory is not a link" do
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

			it "says that the fixture root directory is a directory" do
				@root.should be_directory
			end
		end

		describe "#pipe?" do
			it "says that `p1` is a pipe" do
				(@root / 'p1').should be_pipe
			end

			it "says that `f1` is not a pipe" do
				(@root / 'f1').should_not be_pipe
			end

			it "says that the fixture root directory is not a pipe" do
				@root.should_not be_pipe
			end
		end

		describe "#socket?" do
			it "says that `s1` is a socket" do
				(@root / 's1').should be_socket
			end

			it "says that `f1` is not a socket" do
				(@root / 'f1').should_not be_socket
			end

			it "says that the fixture root directory is not a socket" do
				@root.should_not be_socket
			end
		end

		describe "#hidden?" do
			hidden_paths = [
				'.foorc',
				'foo/.bar',
				'.foo.bar',
			]
			hidden_paths.each do |path|
				it "says that <#{path}> is an hidden file" do
					path.as_path.should be_hidden
				end
			end

			non_hidden_paths = [
				'foo.bar',
				'foo/.bar/baz',
			]
			non_hidden_paths.each do |path|
				it "says that <#{path}> not an hidden file" do
					path.as_path.should_not be_hidden
				end
			end
		end
	end

	describe Filepath::FilesystemInfo do
		describe "#absolute_path" do
			test_data = [
				['d1/l11', File.expand_path('d1/l11', FIXTURES_DIR), FIXTURES_DIR],
				['/foo/bar', '/foo/bar', '.'],
			]
			test_data.each do |path, abs_path, cwd|
				it "resolves <#{path}> to <#{abs_path}> (in #{cwd})" do
					Dir.chdir(cwd) do # FIXME
						Filepath.new(path).absolute_path.should == abs_path
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

	describe Filepath::FilesystemChanges do
		let(:ph) { @root / 'd1' / 'test-file' }

		before(:each) do
			ph.should_not exist
		end

		after(:each) do
			File.delete(ph) if File.exists?(ph)
		end

		describe "#touch" do
			it "creates an empty file" do
				ph.touch
				ph.should exist
			end

			it "updates the modification date of an existing file", :broken => true do
				File.open(ph, "w+") { |file| file << "abc" }
				File.utime(0, Time.now - 3200, ph)

				before_stat = File.stat(ph)
				before_time = Time.now

				#sleep(5) # let Ruby flush its stat buffer to the disk
				ph.touch

				after_time = Time.now
				after_stat = File.stat(ph)

				before_stat.should_not eq(after_stat)

				after_stat.size.should eq(before_stat.size)
				after_stat.mtime.should be_between(before_time, after_time)
			end
		end
	end

	describe Filepath::FilesystemTests do
		describe "mountpoint?" do
			it "says that </proc> is a mount point" do
				"/proc".as_path.should be_mountpoint
			end

			it "says that this RSpec file is not a mount point" do
				__FILE__.as_path.should_not be_mountpoint
			end

			it "says that an non-existing file is not a mount point" do
				"/foo/bar".as_path.should_not be_mountpoint
			end

			it "says that </> is a mount point" do
				"/".as_path.should be_mountpoint
			end
		end
	end

	describe Filepath::ContentInfo do
		let(:ph) { @root / 'd1' / 'test-file' }

		before(:each) do
			ph.should_not exist
		end

		after(:each) do
			File.delete(ph) if File.exists?(ph)
		end

		describe "#read" do
			let(:content) { "a"*20 + "b"*10 + "c"*5 }

			before(:each) do
				ph.open('w') { |f| f << content }
			end

			it "reads the complete content of a file" do
				c = ph.read
				c.should == content
			end

			it "reads the content in chunks of arbitrary sizes" do
				sum = ""
				len = 8

				num_chunks = (content.length.to_f / len).ceil
				num_chunks.times do |i|
					c = ph.read(len, len*i)
					sum += c
					c.should == content[len*i, len]
				end

				sum.should == content
			end
		end

		describe "#readlines" do
			let(:line) { "abcd12" }
			let(:lines) { Array.new(3) { line } }

			it "reads all the lines in the file" do
				ph.open('w') { |file| file << lines.join("\n") }
				readlines = ph.readlines

				readlines.should have(3).lines
				readlines.all? { |l| l.chomp.should == line }
			end

			it "read lines separated by arbitrary separators" do
				sep = ','

				ph.open('w') { |file| file << lines.join(sep) }
				readlines = ph.readlines(sep)

				readlines.should have(3).lines
				readlines[0..-2].all? { |l| l.should == line + sep}
				readlines.last.should == line
			end
		end

		describe "#size" do
			before(:each) do
				ph.touch
			end

			it "says that an empty file contains 0 bytes" do
				ph.size.should be_zero
			end

			it "reports the size of a non-empty file" do
				ph.size.should be_zero

				ph.open("a") { |f| f << "abc" }
				ph.size.should eq(3)

				ph.open("a") { |f| f << "defg" }
				ph.size.should eq(3+4)
			end
		end
	end

	describe Filepath::ContentChanges do
		let(:ph) { @root / 'd1' / 'test-file' }
		let(:content) { "a"*20 + "b"*10 + "c"*5 }

		before(:each) do
			ph.should_not exist
		end

		after(:each) do
			File.delete(ph) if File.exists?(ph)
		end

		describe "#open" do
			before(:each) do
				ph.touch
			end

			it "opens files" do
				file = ph.open
				file.should be_a(File)
			end

			it "opens files in read-only mode" do
				ph.open do |file|
					expect { file << "abc" }.to raise_error(IOError)
				end
			end

			it "opens files in read-write mode" do
				ph.open('w') do |file|
					file << "abc"
				end

				ph.size.should == 3
			end
		end

		describe "#write" do
			it "writes data passed as argument" do
				ph.write(content)

				ph.read.should == content
			end

			it "overwrites an existing file" do
				ph.write(content * 2)
				ph.size.should eq(content.length * 2)

				ph.write(content)
				ph.size.should eq(content.length)

				ph.read.should == content
			end
		end

		describe "#append" do
			it "appends data to an existing file" do
				ph.write(content)
				ph.append(content)

				ph.size.should eq(content.length * 2)
				ph.read.should == content * 2
			end
		end

		describe "#truncate" do
			before(:each) do
				ph.open('w') { |f| f << content }
			end

			it "truncates a file to 0 bytes" do
				ph.size.should_not be_zero
				ph.truncate
				ph.size.should be_zero
			end

			it "truncates a file to an arbitrary size" do
				ph.size.should_not be_zero
				ph.truncate(2)
				ph.size.should == 2
			end
		end
	end

	describe Filepath::ContentTests do
		let(:ph) { @root / 'd1' / 'test-file' }

		before(:each) do
			ph.should_not exist
		end

		after(:each) do
			File.delete(ph) if File.exists?(ph)
		end

		describe "#empty?" do
			before(:each) do
				ph.touch
			end

			it "says that an empty file is empty" do
				ph.should be_empty
			end

			it "says that a non-empyt file is not empty" do
				ph.open('w') { |f| f << "abc" }
				ph.should_not be_empty
			end

			it "says that </dev/null> is empty" do
				'/dev/null'.as_path.should be_empty
			end
		end
	end

	describe Filepath::SearchMethods do
		describe "#entries" do
			it "raises when path is not a directory" do
				expect { (@root / 'f1').entries(:files) }.to raise_error(Errno::ENOTDIR)
			end
		end

		describe "#find" do
			it "finds all paths matching a glob string" do
				list = @root.find('*1')

				list.should have(8).items
				list.each { |path| path.should =~ /1/ }
			end

			it "finds all paths matching a Regex" do
				list = @root.find(/2/)

				list.should have(6).items
				list.each { |path| path.should =~ /2/ }
			end

			it "finds all paths for which the block returns true" do
				list = @root.find { |path| path.directory? }

				list.should have(9).items
				list.each { |path| path.filename.should =~ /^d/ }
			end
		end

		describe "#files" do
			it "finds 1 file in the root directory" do
				@root.files.should have(1).item
			end

			it "finds 3 files in the root directory and its sub directories" do
				@root.files(true).should have(3).item
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

			it "finds 9 directories in the root directory and its sub directories" do
				@root.directories(true).should have(9).item
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

	describe Filepath::EnvironmentInfo
end

describe String do
	describe "#as_path" do
		it "generates a Filepath from a String" do
			path = "/a/b/c".as_path
			path.should be_a(Filepath)
			path.should eq("/a/b/c")
		end
	end
end

describe Array do
	describe "#as_path" do
		it "generates a Filepath from a String" do
			path = ['/', 'a', 'b', 'c'].as_path
			path.should be_a(Filepath)
			path.should eq("/a/b/c")
		end
	end
end
