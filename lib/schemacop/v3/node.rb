module Schemacop
  module V3
    class Node
      attr_reader :name
      attr_reader :as
      attr_reader :default
      attr_reader :title
      attr_reader :description
      attr_reader :options
      attr_reader :parent
      attr_reader :require_key

      class_attribute :_supports_children
      self._supports_children = nil

      def self.supports_children(name: false)
        self._supports_children = { name: name }
      end

      def self.supports_children_options
        _supports_children
      end

      def self.resolve_class(type)
        NodeRegistry.find(type)
      end

      def self.create(type = self, **options, &block)
        klass = resolve_class(type)
        fail "Could not find node for type #{type.inspect}." unless klass

        options = Schemacop.v3_default_options.slice(*klass.allowed_options).merge(options)
        node = klass.new(**options, &block)

        if options.delete(:cast_str)
          format = NodeRegistry.name(klass)
          one_of_options = {
            required:           options.delete(:required),
            treat_blank_as_nil: true,
            name:               options.delete(:name),
            as:                 options.delete(:as),
            description:        options.delete(:description)
          }
          node = create(:one_of, **one_of_options) do
            self.node node
            str format: format, format_options: options
          end
        end

        return node
      end

      def self.allowed_options
        %i[name required default description examples enum parent options title as require_key]
      end

      def self.dsl_methods
        %i[dsl_scm dsl_node]
      end

      def allowed_types
        {}
      end

      def used_external_schemas(encountered_nodes = Set.new)
        return [] if encountered_nodes.include?(self)

        return children.map { |c| c.used_external_schemas(encountered_nodes) }.flatten.uniq
      end

      def children
        []
      end

      def initialize(**options, &block)
        # Check options #
        disallowed_options = options.keys - self.class.allowed_options

        if disallowed_options.any?
          fail Schemacop::Exceptions::InvalidSchemaError, "Options #{disallowed_options.inspect} are not allowed for this node."
        end

        # Assign attributes #
        @name = options.delete(:name)
        @name = @name.to_s unless @name.nil? || @name.is_a?(Regexp)
        @as = options.delete(:as)
        @required = !!options.delete(:required)
        @default = options.delete(:default)
        @title = options.delete(:title)
        @description = options.delete(:description)
        @examples = options.delete(:examples)
        @enum = options.delete(:enum)&.to_set
        @require_key = !!options.delete(:require_key)
        @parent = options.delete(:parent)
        @options = options
        @schemas = {}

        # Run subclass init #
        init

        # Run DSL block #
        if block_given?
          unless self.class.supports_children_options
            fail Schemacop::Exceptions::InvalidSchemaError, "Node #{self.class} does not support blocks."
          end

          scope = DslScope.new(self)
          env = ScopedEnv.new(self, self.class.dsl_methods, scope, :dsl_)
          env.instance_exec(&block)
        end

        # Validate self #
        begin
          validate_self
        rescue StandardError => e
          fail Exceptions::InvalidSchemaError, e.message
        end
      end

      def create(type, **options, &block)
        options[:parent] = self
        return Node.create(type, **options, &block)
      end

      def init; end

      def dsl_scm(name, type = :hash, **options, &block)
        @schemas[name] = create(type, **options, &block)
      end

      def dsl_node(node, *_args, **_kwargs)
        add_child node
      end

      def schemas
        (parent&.schemas || {}).merge(@schemas)
      end

      def required?
        @required
      end

      def require_key?
        @require_key
      end

      def as_json
        process_json([], {})
      end

      def cast(value)
        value || default
      end

      def validate(data)
        result = Result.new(self, data)
        _validate(data, result: result)
        return result
      end

      protected

      def context
        Schemacop.context
      end

      def item_matches?(item, data)
        item_result = Result.new(self)
        item._validate(data, result: item_result)
        return item_result.errors.none?
      end

      def process_json(attrs, json)
        if !context.swagger_json? && @schemas.any?
          json[:definitions] = {}
          @schemas.each do |name, subschema|
            json[:definitions][name] = subschema.as_json
          end
        end

        attrs.each do |attr|
          if options.include?(attr)
            json[attr.to_s.camelize(:lower).to_sym] = options[attr]
          end
        end

        json[:title] = @title if @title
        json[context.swagger_json? ? :example : :examples] = @examples if @examples
        json[:description] = @description if @description
        json[:default] = @default unless @default.nil?
        json[:enum] = @enum.to_a if @enum
        json[:require_key] = @require_key if @require_key

        return json.as_json
      end

      def parse_if_json(data, allowed_types:, result: nil)
        if data.is_a?(String)
          data = JSON.parse(data)

          if result && !validate_type(data, result, allowed_types: allowed_types)
            return nil
          end
        end

        return data
      rescue JSON::ParserError => e
        result&.error "JSON parse error: #{e.message.inspect}."
        return nil
      end

      def type_assertion_method
        :is_a?
      end

      def _validate(data, result:)
        # Validate nil #
        if data.nil? && required?
          result.error 'Value must be given.'
          return nil
        end

        # Apply default #
        if data.nil?
          if default.nil?
            return nil
          else
            data = default
          end
        end

        # Validate type #
        return nil unless validate_type(data, result)

        # Validate enums #
        if @enum && !@enum.include?(data)
          result.error "Value not included in enum #{@enum.to_a.inspect}."
        end

        return data
      end

      def validate_type(data, result, allowed_types: self.allowed_types)
        if allowed_types.any? && allowed_types.keys.none? { |c| data.send(type_assertion_method, c) }
          collection = allowed_types.values.map { |t| "\"#{t}\"" }.uniq.sort.join(' or ')
          result.error "Invalid type, got type \"#{data.class}\", expected #{collection}."
          return false
        end

        return true
      end

      def validate_self; end
    end
  end
end
