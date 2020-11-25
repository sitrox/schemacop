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
        super + ATTRIBUTES + %i[additional_items contains]
      end

      def self.dsl_methods
        super + %i[dsl_str dsl_obj dsl_int dsl_boo dsl_ary
                   dsl_num dsl_ref dsl_sym dsl_all_of dsl_any_of
                   dsl_one_of dsl_is_not dsl_add dsl_hsh]
      end

      attr_reader :items

      def dsl_add(type, **options, &block)
        @options[:additional_items] = create(type, **options, &block)
      end

      def add_child(node)
        @items << node
      end

      def as_json
        json = { type: :array }

        if @items.any?
          if options[:contains]
            json[:contains] = @items.first.as_json
          else
            json[:items] = @items.map(&:as_json)
          end
        end

        if options[:additional_items] == true
          json[:additionalItems] = true
        elsif options[:additional_items].is_a?(Node)
          json[:additionalItems] = options[:additional_items].as_json
        elsif @items.any? && !options[:contains]
          json[:additionalItems] = false
        end

        return process_json(ATTRIBUTES, json)
      end

      def allowed_types
        { Array => :array }
      end

      def _validate(data, result:)
        data = super
        return if data.nil?

        # Validate length #
        length = data.size

        if options[:min_items] && length < options[:min_items]
          result.error "Array has #{length} items but needs at least #{options[:min_items]}."
        end

        if options[:max_items] && length > options[:max_items]
          result.error "Array has #{length} items but needs at most #{options[:max_items]}."
        end

        # Validate contains #
        if options[:contains]
          fail 'Array nodes with "contains" must have exactly one item.' unless items.size == 1
          item = items.first

          unless data.any? { |obj| item_matches?(item, obj) }
            result.error "At least one entry must match schema #{item.as_json.inspect}."
          end
        # Validate list #
        elsif items.size == 1
          node = items.first

          data.each_with_index do |value, index|
            result.in_path :"[#{index}]" do
              node._validate(value, result: result)
            end
          end

        # Validate tuple #
        elsif items.size > 1
          if length == items.size || (options[:additional_items] != false && length >= items.size)
            items.each_with_index do |node, index|
              value = data[index]

              result.in_path :"[#{index}]" do
                node._validate(value, result: result)
              end
            end

            # Validate additional items #
            if options[:additional_items].is_a?(Node)
              (items.size..(length - 1)).each do |index|
                additional_item = data[index]
                result.in_path :"[#{index}]" do
                  options[:additional_items]._validate(additional_item, result: result)
                end
              end
            end
          else
            result.error "Array has #{length} items but must have exactly #{items.size}."
          end
        end

        # Validate uniqueness #
        if options[:unique_items] && data.size != data.uniq.size
          result.error 'Array has duplicate items.'
        end
      end

      def children
        (@items + [@contains]).compact
      end

      def cast(value)
        return default unless value

        result = []

        value.each do |value_item|
          item = item_for_data(value_item)
          result << item.cast(value_item)
        end

        return result
      end

      protected

      def item_for_data(data)
        item = children.find { |c| item_matches?(c, data) }
        return item if item
        fail "Could not find specification for item #{data.inspect}."
      end

      def init
        @items = []
        @contains = nil

        if options[:additional_items].nil?
          options[:additional_items] = false
        end
      end
    end
  end
end
