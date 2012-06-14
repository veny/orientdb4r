module Orientdb4r

  ###
  # This mixin extends an error to be able to track a chain of exceptions.
  module ChainedError

    attr_reader :cause

    ###
    # Constructor.
    def initialize message = nil, cause = $!
      super message unless message.nil?
      super $! if message.nil? and !cause.nil?
      @cause = cause
    end

    ###
    # Modification of original method Error#set_backtrace
    # to descend the full depth of the exception chain.
    def set_backtrace bt
      unless cause.nil?
        cause.backtrace.reverse.each do |line|
          if bt.last == line
            bt.pop
            next
          end
          break
        end
        bt.push "<<<CAUSED BY>>>: #{cause.class}: #{cause.message}"
        bt.concat cause.backtrace
      end
      super bt
    end

  end

end
