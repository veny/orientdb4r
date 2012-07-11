require 'orientdb4r'

module Elaboration

  ###
  # This class represents a elaboration infrastructure.
  class Case

    attr_reader :dg

    def initialize
      @dg = DataGenerator.new
    end

    def db
      'temp' # default DB is 'temp'
    end
    def host
      'localhost'
    end

    def client
      Orientdb4r.client :host => host
    end

    def watch method
        start = Time.now
        self.send method.to_sym
        Orientdb4r::logger.info "method '#{method}' performed in #{Time.now - start} [s]"
    end

    def run
      threads = []
#      1.upto(1) do
#        threads << Thread.new do
#          Orientdb4r::logger.info "started thread #{Thread.current}"
          client.connect :database => db, :user => 'admin', :password => 'admin'
          ARGV.each do |arg|
            watch arg[2..-1].to_sym if arg =~ /^--\w/
          end
          client.disconnect
#        end # Thread
#      end
#      threads.each { |th|  th.join }
    end

  end


  class DataGenerator

    def initialize
      @words = IO.readlines('/usr/share/dict/words')
      0.upto(@words.size - 1) do |i|
        word = @words[i]
        word.strip!.downcase!
        idx = word.index("'")
        word = word[0..(idx - 1)] unless idx.nil?
        @words[i] = word
      end
      @words.uniq!
      Orientdb4r::logger.info "DataGenerator: #{@words.size} words"
    end

    # Gets a random word.
    def word
      @words[rand(@words.size)]
    end

  end

end
