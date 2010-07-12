module Dragonfly
  class FunctionManager
    
    include Loggable
    
    def initialize
      @functions = {}
      @objects = []
    end
    
    def add(name, callable_obj=nil, &block)
      functions[name] ||= []
      functions[name] << (callable_obj || block)
    end

    attr_reader :functions, :objects

    def register(klass, *args, &block)
      obj = klass.new(*args)
      obj.configure(&block) if block
      obj.use_same_log_as(self) if obj.is_a?(Loggable)
      methods_to_add(obj).each do |meth|
        add meth.to_sym, obj.method(meth)
      end
      objects << obj
      obj
    end
    
    def call_last(meth, *args)
      functions[meth.to_sym].reverse.each do |function|
        catch :unable_to_handle do
          return function[*args]
        end
      end
    end

    alias call call_last

    private
    
    def methods_to_add(obj)
      if obj.is_a?(Configurable)
        obj.public_methods(false) -
          obj.configuration_methods.map{|meth| meth.to_method_name} -
          [:configuration_methods.to_method_name]
      else
        obj.public_methods(false)
      end
    end

  end
end
