module Schemacop::V2
  class NodeSupportingType < NodeWithBlock
    block_method :type

    def self.build(options, &block)
      new(nil, options, &block)
    end

    def initialize(options = {}, &block)
      super(options)

      @types = []
      exec_block(&block)

      if @types.none?
        fail Exceptions::InvalidSchemaError, 'Block must contain a type definition or not be given at all.' if block_given?

        type :object
      end

      # if @types.none?
      #   super(options)
      #   exec_block(&block)
      #   if @types.none?
      #     fail Exceptions::InvalidSchemaError, 'Block must contain a type definition or not be given at all.' if block_given?
      #   end
      # else
      #   super({})
      # end
    end

    def exec_block(&block)
      super
    rescue NoMethodError
      @types = []
      type :hash, &block
    end

    # required signature:
    # First argument must be a type or an array of types
    # Following arguments may be subtypes
    # Last argument may be an options hash.
    # Options and given block are passed to the last specified type.
    # Not permitted to give subtypes / options / a block if an array of types is given.
    #
    # TODO: Probably change this method so that the 'rescue NoMethodError'
    # happens in here directly and not in the constructor. This way we can
    # always call 'type', even if we don't have one and the type is auto-guessed
    # as it formerly was the case in the constructor.
    def type(*args, **kwargs, &block)
      options = kwargs
      types = [*args.shift]
      subtypes = args

      unless types.any?
        fail Exceptions::InvalidSchemaError, 'At least one type must be given.'
      end

      if subtypes.any? && types.size > 1
        fail Exceptions::InvalidSchemaError, "First given type can't be an array if subtypes are given."
      end

      if types.size > 1 && options.any?
        fail Exceptions::InvalidSchemaError, 'No options can be specified if multiple types are given.'
      end

      types.each do |type|
        klass = resolve_type_klass(type)

        if subtypes.any?
          unless klass <= NodeSupportingType
            fail "Node #{klass} does not support subtypes."
          end

          child = klass.new do
            self.type(*subtypes, **options, &block)
          end

          # child = klass.build(options)
          #
          #
          # child.type(*subtypes, &block)
        else
          if klass == ObjectValidator && type.is_a?(Class)
            options[:classes] = type
          end

          child = klass.new(options, &block)
        end

        @types << child
      end
    end

    def validate(data, collector)
      super
      validate_types(data, collector)
    end

    protected

    def cast!(data, collector)
      @types.each do |type|
        next unless type.option?(:cast) && !type.type_matches?(data) && type.type_filter_matches?(data)

        caster = Caster.new(type.option(:cast), data, type.class.klasses.first)

        next unless caster.castable?

        begin
          data = caster.cast
          collector.override_value(data)
          return data
        rescue Exceptions::InvalidSchemaError => e
          collector.error e.message
        end
      end

      return data
    end

    def validate_types(data, collector)
      data = cast!(data, collector)
      unless (match = @types.find { |t| t.type_matches?(data) })
        allowed_types = @types.map(&:type_label)

        collector.error "Data type not matching: #{data.class}, allowed types: #{allowed_types.join('; ')}"
        return
      end
      match.validate(data, collector)
    end
  end
end
