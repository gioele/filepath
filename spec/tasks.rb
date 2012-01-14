# This is free and unencumbered software released into the public domain.
# See the `UNLICENSE` file or <http://unlicense.org/> for more details.

FIXTURES_DIR = File.join(%w{spec fixtures})
FIXTURES_FAKE_ENTRIES = [
	'd1',
		['d1', 'd11'],
		['d1', 'd12'],
		['d1', 'd13'],
		['d1', 'f11'],
		['d1', 'f12'],
		['d1', 'l11'],
	'd2',
		['d2', 'd21'],
		['d2', 'd22'],
	'd3',
	'f1',
	'dx',
].map { |entry| File.join(FIXTURES_DIR, *Array(entry)) }

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

		desc "Generate fake dirs and files"
		task :gen => FIXTURES_FAKE_ENTRIES
	end
end
