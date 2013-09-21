# This is free software released into the public domain (CC0 license).

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
	'p1',
	'p2',
	's1',
].map { |entry| File.join(FIXTURES_DIR, *Array(entry)) }
