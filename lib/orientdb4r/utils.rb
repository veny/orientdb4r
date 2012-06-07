module Orientdb4r

  module Utils

    def verify_options(options, pattern)
      # unknown key?
      options.keys.each do |k|
        raise ArgumentError, "unknow option: #{k}" unless pattern.keys.include? k
      end
      # missing mandatory option?
      pattern.each do |k,v|
        raise ArgumentError, "missing mandatory option: #{k}" if v == :mandatory and !options.keys.include? k
      end
      options
    end

    def verify_and_sanitize_options(options, pattern)
      verify_options(options, pattern)

      # set default values if missing in options
      pattern.each do |k,v|
        options[k] = v if !v.nil? and !options.keys.include? k
      end
      options
    end


    ###
    # Checks if a given string is either 'nil' or empty string.
    def blank?(str)
      str.nil? or str.strip.empty?
    end

  end


  # TODO extend it to work with already defined methods ('before :foo, :baz' after method definition)
  module Aop2

    def self.included(base)
      base.extend ClassMethods2
      base.init_aop_extension
    end

    def aop_context
      Thread.current[:aop2_context]
    end
    def aop_context=(ctx={})
      Thread.current[:aop2_context] = ctx
    end

    module ClassMethods2

      def init_aop_extension
        @hooks = {}
        [:before, :after, :around].each { |where| @hooks[where] = Hash.new { |hash, key| hash[key] = [] }}
        # will be like this:
        # {:before=>{:disconnect=>[:assert_connected], :query=>[:assert_connected], :command=>[:assert_connected]}, :after=>{}, :around=>{}}
        class << self
          attr_reader :hooks
        end
        @@redefining = false # flag whether the process of method redefining is running
      end
      def method_added(method)
        unless @@redefining # avoid recursion
          redefine_method(method) if is_hooked?(method)
        end
      end

      #----------------------------------------------------------------- Helpers

      def is_hooked?(method)
        # look into array of keys (method names) in 2nd level hashs (see above)
        hooks.values.map(&:keys).flatten.uniq.include? method
      end



      def before(original_method, *hooks)
        add_hook(:before, original_method, *hooks)
      end
      def after(original_method, *hooks)
        add_hook(:after, original_method, *hooks)
      end
      def around(original_method, *hooks)
        add_hook(:around, original_method, *hooks)
      end


      def add_hook(type, original_method, *hooks) #!!
        Array(original_method).each do |method|
          store_hook(type, method, *hooks)
        end
      end
      def store_hook(type, method_name, *hook_methods) #!!
        hooks[type.to_sym][method_name.to_sym] += hook_methods.flatten.map(&:to_sym)
      end

      def redefine_method(orig_method)
        @@redefining = true

        arity = instance_method(orig_method.to_sym).arity
        params = ''
        fixed_cnt = arity.abs
        fixed_cnt -= 1 if arity < 0
        # build up a list of params
        1.upto(fixed_cnt).each {|x| params << "p#{x},"}
        params << "*argv" if arity < 0
        params.gsub!(/,$/, '') # remove last ','

        alias_method "#{orig_method}_aop2_orig".to_sym, orig_method.to_sym

        class_eval <<-FILTER,__FILE__,__LINE__ + 1
          def #{orig_method}(#{params})
            self.aop_context = { :method => '#{orig_method}', :class => self.class }
            begin
              self.class.invoke_hooks(self, :before, :#{orig_method})
              rslt = self.class.invoke_arround_hooks(self, :#{orig_method}, self.class.hooks[:around][:#{orig_method}].clone) {
                #{orig_method}_aop2_orig(#{params})
              }
              self.class.invoke_hooks(self, :after, :#{orig_method})
#            rescue Exception => e
#              # TODO use logging
#              $stderr.puts '' << e.class.name << ': ' << e.message
#              $stderr.puts e.backtrace.inspect
#              raise e
            ensure
              self.aop_context = nil
            end
            rslt
          end
        FILTER

        @@redefining = false
      end

      def invoke_hooks(obj, hook_type, method_name)
        hooks[hook_type][method_name.to_sym].each { |hook| obj.send hook }
      end
      def invoke_arround_hooks(obj, method_name, hooks, &block)
        hook = hooks.slice! 0
        return block.call if hook.nil? # call original method if no more hook

        # invoke the hook with lambda containing recursion
        obj.send(hook.to_sym) { invoke_arround_hooks(obj, method_name, hooks, &block); }
      end

    end # ClassMethods2
  end # Aop2

end
