module Orientdb4r

  ###
  # Base class for implementation of load balancing strategy.
  class LBStrategy

    # If occures a new try to communicate from node can be tested.
    RECOVERY_TIMEOUT = 30

    attr_reader :nodes_count

    ###
    # Constructor.
    def initialize nodes_count
      @nodes_count = nodes_count
      @bad_nodes = {}
    end

    ###
    # Gets index of node to be used for next request
    # or 'nil' if there is no one next.
    def node_index
      raise NotImplementedError, 'this should be overridden in subclass'
    end

    ###
    # Marks an index as good that means it can be used for next server calls.
    def good_one(idx)
      @bad_nodes.delete idx
    end

    ###
    # Marks an index as bad that means it will be not used until:
    # * there is other 'good' node
    # * timeout
    def bad_one(idx)
      @bad_nodes[idx] = Time.now
    end

    protected

      def search_next_good(bad_idx)
        Orientdb4r::logger.warn "identified bad node, idx=#{bad_idx}, age=#{Time.now - @bad_nodes[bad_idx]} [s]"
        1.upto(nodes_count) do |i|
          candidate = (i + bad_idx) % nodes_count
          unless @bad_nodes.include? candidate
            Orientdb4r::logger.debug "found good node, idx=#{candidate}"
            return candidate
          end
        end

        # TODO implement search based on LRU for next round

        Orientdb4r::logger.error 'no nodes more, all invalid'
        nil
      end

  end

  ###
  # Implementation of Sequence strategy.
  # Assigns work in the order of nodes defined by the client initialization.
  class Sequence < LBStrategy

    def node_index #:nodoc:
      @last_index = 0 if @last_index.nil?

      @last_index = search_next_good(@last_index) if @bad_nodes.include? @last_index
      @last_index
    end

  end

  ###
  # Implementation of Round Robin strategy.
  # Assigns work in round-robin order per nodes defined by the client initialization.
  class RoundRobin < LBStrategy

    def node_index #:nodoc:
      @last_index = -1 if @last_index.nil?

      @last_index = (@last_index + 1) % nodes_count
      @last_index = search_next_good(@last_index) if @bad_nodes.include? @last_index
      @last_index
    end

  end

end
