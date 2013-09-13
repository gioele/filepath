# This is free software released into the public domain (CC0 license).

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib]))
$LOAD_PATH.unshift(LIB_DIR) unless $LOAD_PATH.include?(LIB_DIR)

require 'filepath'

RSpec.configure do |config|
	config.filter_run_excluding :broken => true
end

FIXTURES_DIR = File.join(%w{spec fixtures})
