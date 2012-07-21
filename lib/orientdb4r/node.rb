module Orientdb4r

  ###
  # This class represents a single sever/node
  # in the Distributed Multi-Master Architecture.
  class Node
    include Utils

    attr_reader :host, :port # they are immutable

    ###
    # Constructor.
    def initialize(host, port)
      raise ArgumentError, 'host cannot be blank' if blank? host
      raise ArgumentError, 'port cannot be blank' if blank? port
      @host = host
      @port = port
    end


    ###
    # Cleans up resources used by the node.
    def cleanup
      raise NotImplementedError, 'this should be overridden by subclass'
    end


    ###
    # Gets URL of the remote node.
    def url
      raise NotImplementedError, 'this should be overridden by subclass'
    end

  end

end
