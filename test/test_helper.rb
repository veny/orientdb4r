require 'test/unit'

require 'orientdb4r'
Orientdb4r::logger.level = Logger::FATAL

$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
