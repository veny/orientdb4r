require 'test/unit'
require 'coveralls'
Coveralls.wear!

$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'orientdb4r'

Orientdb4r::logger.level = Logger::FATAL
