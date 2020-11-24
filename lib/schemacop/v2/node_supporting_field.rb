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

    def req?(*args, &block)
      field(*args, required: true, allow_nil: true, &block)
    end

    def req!(*args, &block)
      field(*args, required: true, allow_nil: false, &block)
    end

    alias_method :req, :req!

    def opt?(*args, &block)
      field(*args, required: false, allow_nil: true, &block)
    end

    def opt!(*args, &block)
      field(*args, required: false, allow_nil: false, &block)
    end

    alias_method :opt, :opt?

    protected

    def field(*args, required:, allow_nil:, &block)
      name = args.shift

      if @fields[name]
        @fields[name].type(*args, &block)
      else
        if args.any?
          @fields[name] = FieldNode.new(name, required) do
            type(*args, &block)
          end
        else
          @fields[name] = FieldNode.new(name, required, &block)
        end
      end

      @fields[name].type(:nil) if allow_nil
    end
  end
end
