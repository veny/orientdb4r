module Orientdb4r

  ###
  # This class represents encapsulation of RecordID.
  class Rid
    include Utils

    # Format validation regexp.
    RID_REGEXP_PATTERN = /^#?\d+:\d+$/

    attr_reader :cluster_id, :document_id

    ###
    # Constructor.
    def initialize(rid)
      raise ArgumentError, 'RID cannot be blank' if blank? rid
      raise ArgumentError, 'RID is not String' unless rid.is_a? String
      raise ArgumentError, "bad RID format, rid=#{rid}" unless rid =~ RID_REGEXP_PATTERN

      rid = rid[1..-1] if rid.start_with? '#'
      ids = rid.split ':'
      self.cluster_id = ids[0].to_i
      self.document_id = ids[1].to_i
    end

    ###
    # Setter fo cluster ID.
    def cluster_id=(cid)
      @cluster_id = cid.to_i
    end

    ###
    # Setter fo document ID.
    def document_id=(did)
      @document_id = did.to_i
    end

    def to_s #:nodoc:
      "##{cluster_id}:#{document_id}"
    end

    ###
    # Gets RID's string representation with no prefix.
    def unprefixed
      "#{cluster_id}:#{document_id}"
    end

    def ==(another_rid) #:nodoc:
      self.cluster_id == another_rid.cluster_id and self.document_id == another_rid.document_id
    end

  end

end
