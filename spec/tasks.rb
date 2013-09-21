# This is free software released into the public domain (CC0 license).

require 'rake/clean'

require File.join(File.dirname(__FILE__), 'fixtures')

CLEAN.concat FIXTURES_FAKE_ENTRIES

namespace :spec do
	namespace :fixtures do
		rule %r{/d[0-9x]+$} do |t|
			mkdir_p t.name
		end

		rule %r{/f[0-9]+$} do |t|
			touch t.name
		end

		rule %r{/l[0-9]+$} do |t|
			ln_s '/dev/null', t.name
		end

		rule %r{/p[0-9]+$} do |t|
			system "mkfifo #{t.name}"
		end

		rule %r{/s[0-9]+$} do |t|
			require 'socket'
			UNIXServer.new(t.name)
		end

		desc "Generate fake dirs and files"
		task :gen => FIXTURES_FAKE_ENTRIES
	end
end
