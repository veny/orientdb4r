require 'orientdb4r/bin/protocol28'

module Orientdb4r
  
  class ProtocolFactory

	PROTOCOLS = {
		28 => Orientdb4r::Binary::Protocol28
	}

	def self.get_protocol(version)
	  return PROTOCOLS[version] if PROTOCOLS.include? version

	  #search for a smaller one
	  PROTOCOLS.keys.sort.each do |key|
	  	next if key > version
	  	return if key < version
	  end

	  raise OrientdbError, "Unsupported protocol version, desired=#{version}, supported=#{PROTOCOLS.key.sort}"
	end
  
  end

end