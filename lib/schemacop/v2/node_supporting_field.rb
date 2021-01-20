module Schemacop::V2
  class NodeSupportingField < NodeWithBlock
    block_method :req?
    block_method :req!
    block_method :req
    block_method :opt?
    block_method :opt!
    block_method :opt

    attr_reader :fields

    def initialize(options = {}, &block)
      @fields = {}
      super
      exec_block(&block)
    end

    def req?(*args, **kwargs, &block)
      kwargs ||= {}
      kwargs[:required] = true
      kwargs[:allow_nil] = true
      field(*args, **kwargs, &block)
    end

    def req!(*args, **kwargs, &block)
      kwargs ||= {}
      kwargs[:required] = true
      kwargs[:allow_nil] = false
      field(*args, **kwargs, &block)
    end

    alias req req!

    def opt?(*args, **kwargs, &block)
      kwargs ||= {}
      kwargs[:required] = false
      kwargs[:allow_nil] = true
      field(*args, **kwargs, &block)
    end

    def opt!(*args, **kwargs, &block)
      kwargs ||= {}
      kwargs[:required] = false
      kwargs[:allow_nil] = false
      field(*args, **kwargs, &block)
    end

    alias opt opt?

    protected

    def field(*args, **kwargs, &block)
      name = args.shift
      required = kwargs.delete(:required)
      allow_nil = kwargs.delete(:allow_nil)

      if @fields[name]
        @fields[name].type(*args, **kwargs, &block)
      elsif args.any?
        @fields[name] = FieldNode.new(name, required) do
          type(*args, **kwargs, &block)
        end
      else
        @fields[name] = FieldNode.new(name, required, &block)
      end

      @fields[name].type(:nil) if allow_nil
    end
  end
end
