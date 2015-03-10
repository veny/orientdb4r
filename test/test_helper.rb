require 'coveralls'
Coveralls.wear!

require 'test/unit'

$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'orientdb4r'

Orientdb4r::logger.level = Logger::FATAL
DB_ROOT_PASS = ENV['ORIENTDB_ROOT_PASS'] || 'root'
