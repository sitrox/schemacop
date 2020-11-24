module Schemacop
  class Node
    extend T::Sig

    attr_reader :name
    attr_reader :default
    attr_reader :description
    attr_reader :options
    attr_reader :parent

    def self.resolve_class(type)
      "Schemacop::#{type.to_s.classify}Node".safe_constantize
    end

    def self.create(type, **options, &block)
      klass = resolve_class(type)
      fail "Could not find node for type #{type.inspect}." unless klass

      node = klass.new(**options, &block)

      if options.delete(:cast_str)
        one_of_options = {
          required: options.delete(:required),
          name:     options.delete(:name)
        }
        node = create(:one_of, **one_of_options) do
          add_item node
          add_item Node.create(:string, format: type, format_options: options)
        end
      end

      return node
    end

    def self.allowed_options
      %i[name required default description example enum parent options cast_str]
    end

    def self.dsl_methods
      %i[dsl_scm]
    end

    def used_external_schemas
      children.map(&:used_external_schemas).flatten.uniq
    end

    def children
      []
    end

    def initialize(**options, &block)
      # Check options #
      disallowed_options = options.keys - self.class.allowed_options

      if disallowed_options.any?
        fail "Options #{disallowed_options.inspect} are not allowed for this node."
      end

      # Assign attributes #
      @name = options.delete(:name)
      @required = !!options.delete(:required)
      @default = options.delete(:default)
      @description = options.delete(:description)
      @example = options.delete(:example)
      @enum = options.delete(:enum)&.to_set
      @parent = options.delete(:parent)
      @options = options
      @schemas = {}

      # Run subclass init #
      init

      # Run DSL block #
      if block_given?
        env = ScopedEnv.new(self, self.class.dsl_methods, nil, :dsl_)
        env.instance_exec(&block)
      end

      # Validate self #
      validate_self
    end

    def create(type, **options, &block)
      options[:parent] = self
      return Node.create(type, **options, &block)
    end

    def init; end

    sig { params(name: Symbol, type: Symbol, options: Object, block: T.nilable(T.proc.void)).void }
    def dsl_scm(name, type = :object, **options, &block)
      @schemas[name] = create(type, **options, &block)
    end

    def schemas
      (parent&.schemas || {}).merge(@schemas)
    end

    def required?
      @required
    end

    def as_json
      {}
    end

    def validate(data)
      result = Result.new(self, data)
      _validate(data, result: result)
      return result
    end

    def cast(value)
      value || default
    end

    protected

    sig { params(data: T.nilable(Object), type: T.any(T::Array[Class], Class), type_name: Symbol, result: Result).returns(T.nilable(Object)) }

    def validate_type(data, type, type_name, result)
      types = Array(type)

      if data.nil? && default
        data = default
      elsif types.none? { |t| data.is_a?(t) }
        result.error %(Invalid type, expected #{type_name.to_s.inspect}.)
        data = nil
      end

      return data
    end

    def item_matches?(item, data)
      item_result = Result.new(self)
      item._validate(data, result: item_result)
      return item_result.errors.none?
    end

    def process_json(attrs, json)
      attrs.each do |attr|
        if options.include?(attr)
          json[attr.to_s.camelize(:lower).to_sym] = options[attr]
        end
      end

      json[:example] = @example if @example
      json[:description] = @description if @description
      json[:default] = @default if @default
      json[:enum] = @enum.to_a if @enum

      return json.as_json
    end

    def _validate(data, result:)
      if @enum && !@enum.include?(data)
        result.error "Value not included in enum #{@enum.to_a.inspect}."
      end

      return result
    end

    # def collect(_data)
    #   nil
    # end

    def validate_self; end
  end
end
