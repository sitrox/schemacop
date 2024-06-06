module Schemacop
  module V3
    class ArrayNode < Node
      ATTRIBUTES = %i[
        min_items
        max_items
        unique_items
      ].freeze

      supports_children

      def self.allowed_options
        super + ATTRIBUTES + %i[additional_items reject filter parse_json]
      end

      def self.dsl_methods
        super + NodeRegistry.dsl_methods(false) + %i[dsl_add dsl_list dsl_cont]
      end

      attr_reader :items
      attr_accessor :list_item
      attr_accessor :cont_item

      def dsl_add(type, **options, &block)
        if @options[:additional_items].is_a?(Node)
          fail Exceptions::InvalidSchemaError, 'You can only use "add" once to specify additional items.'
        end

        @options[:additional_items] = create(type, **options, &block)
      end

      def dsl_list(type, **options, &block)
        if list_item.is_a?(Node)
          fail Exceptions::InvalidSchemaError, 'You can only use "list" once.'
        end

        @list_item = create(type, **options, &block)
      end

      def dsl_cont(type, **options, &block)
        if cont_item.is_a?(Node)
          fail Exceptions::InvalidSchemaError, 'You can only use "cont" once.'
        end

        @cont_item = create(type, **options, &block)
      end

      def add_child(node)
        @items << node
      end

      def as_json
        json = { type: :array }

        if cont_item
          json[:contains] = cont_item.as_json
        end

        if list?
          json[:items] = @list_item.as_json
        elsif @items.any?
          json[:items] = @items.map(&:as_json)
          if options[:additional_items] == true
            json[:additionalItems] = true
          elsif options[:additional_items].is_a?(Node)
            json[:additionalItems] = options[:additional_items].as_json
          else
            json[:additionalItems] = false
          end
        end

        return process_json(ATTRIBUTES, json)
      end

      def allowed_types
        if options[:parse_json]
          { Array => :array, String => :array }
        else
          { Array => :array }
        end
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        # Handle JSON
        super_data = parse_if_json(super_data, result: result, allowed_types: { Array => :array })
        return if super_data.nil?

        # Preprocess
        super_data = preprocess_array(super_data)

        # Validate length
        length = super_data.size

        if options[:min_items] && length < options[:min_items]
          result.error "Array has #{length} items but needs at least #{options[:min_items]}."
        end

        if options[:max_items] && length > options[:max_items]
          result.error "Array has #{length} items but needs at most #{options[:max_items]}."
        end

        if list?
          # Validate list
          super_data.each_with_index do |value, index|
            result.in_path :"[#{index}]" do
              list_item._validate(value, result: result)
            end
          end
        elsif items.any?
          # Validate tuple
          if length == items.size || (options[:additional_items] != false && length >= items.size)
            items.each_with_index do |child_node, index|
              value = super_data[index]

              result.in_path :"[#{index}]" do
                child_node._validate(value, result: result)
              end
            end

            # Validate additional items #
            if options[:additional_items].is_a?(Node)
              (items.size..(length - 1)).each do |index|
                additional_item = super_data[index]
                result.in_path :"[#{index}]" do
                  options[:additional_items]._validate(additional_item, result: result)
                end
              end
            end
          else
            result.error "Array has #{length} items but must have exactly #{items.size}."
          end
        end

        if cont_item.present? && super_data.none? { |obj| item_matches?(cont_item, obj) }
          result.error "At least one entry must match schema #{cont_item.as_json.inspect}."
        end

        # Validate uniqueness #
        if options[:unique_items] && super_data.size != super_data.uniq.size
          result.error 'Array has duplicate items.'
        end
      end

      def children
        (@items + [@cont_item]).compact
      end

      def cast(value)
        return default unless value

        value = parse_if_json(value, allowed_types: { Array => :array })

        result = []

        value.each_with_index do |value_item, index|
          if cont_item.present? && item_matches?(cont_item, value_item)
            result << cont_item.cast(value_item)
          elsif list?
            result << list_item.cast(value_item)
          elsif items.any?
            if options[:additional_items] != false && index >= items.size
              if options[:additional_items].is_a?(Node)
                result << options[:additional_items].cast(value_item)
              else
                result << value_item
              end
            else
              item = item_for_data(value_item)
              result << item.cast(value_item)
            end
          else
            result << value_item
          end
        end

        return preprocess_array(result)
      end

      protected

      def preprocess_array(value)
        # Handle filter
        if options[:filter]
          block = Proc.new(&options[:filter])

          value = value.filter do |item|
            block.call(item)
          rescue NoMethodError
            true
          end
        end

        # Handle reject
        if options[:reject]
          block = Proc.new(&options[:reject])

          value = value.reject do |item|
            block.call(item)
          rescue NoMethodError
            false
          end
        end

        return value
      end

      def list?
        list_item.present?
      end

      def item_for_data(data)
        item = children.find { |c| item_matches?(c, data) }
        return item if item

        fail "Could not find specification for item #{data.inspect}."
      end

      def init
        @items = []
        @cont_item = nil

        if options[:additional_items].nil?
          options[:additional_items] = false
        end
      end

      def validate_self
        if list? && items.any?
          fail 'Can\'t use "list" and normal items.'
        end

        if list? && @options[:additional_items].is_a?(Node)
          fail 'Can\'t use "list" and additional items.'
        end

        unless options[:min_items].nil? || options[:min_items].is_a?(Integer)
          fail 'Option "min_items" must be an "integer"'
        end

        unless options[:max_items].nil? || options[:max_items].is_a?(Integer)
          fail 'Option "max_items" must be an "integer"'
        end

        unless options[:unique_items].nil? || options[:unique_items].is_a?(TrueClass) || options[:unique_items].is_a?(FalseClass)
          fail 'Option "unique_items" must be a "boolean".'
        end

        if options[:min_items] && options[:max_items] && options[:min_items] > options[:max_items]
          fail 'Option "min_items" can\'t be greater than "max_items".'
        end
      end
    end
  end
end
