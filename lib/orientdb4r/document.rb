module Orientdb4r

  ###
  # This class represents a document.
  class Document < Hash
    include DocumentMetadata

    def initialize(options={})
      super

      options.each do |k,v|
        self[k] = v
      end
    end

    def [key]=value
      super[key.to_s] = value
    end

  end

end
