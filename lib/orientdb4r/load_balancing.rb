module Orientdb4r

  ###
  # Base class for implementation of load balancing strategy.
  class LBStrategy

    attr_reader :nodes_count

    ###
    # Constructor.
    def initialize nodes_count
      @nodes_count = nodes_count
    end

    ###
    # Gets index of node to be used for next request.
    def node_index
      raise NotImplementedError, 'this should be overridden in subclass'
    end

  end

  ###
  # Implementation of Round Robin strategy.
  class RoundRobin < LBStrategy

    def node_index #:nodoc:
      @last_index = -1 if @last_index.nil?
      @last_index = (@last_index + 1) % nodes_count
      @last_index
    end

  end

  ###
  # Implementation of Sequence strategy.
  class Sequence < LBStrategy

    def node_index #:nodoc:
      @last_index = 0 if @last_index.nil?
      @last_index
    end

  end

end
