module Schemacop
  module V3
    # @abstract
    class CombinationNode < Node
      def self.dsl_methods
        super + NodeRegistry.dsl_methods(false)
      end

      supports_children

      def init
        @items = []
      end

      def as_json
        process_json([], type => @items.map(&:as_json))
      end

      def cast(value)
        item = match(value)
        return value unless item

        return item.cast(value)
      end

      def children
        @items
      end

      def add_child(node)
        @items << node
      end

      protected

      def type
        fail NotImplementedError
      end

      def match(data)
        matches(data).first
      end

      def matches(data)
        @items.select { |i| item_matches?(i, data) }
      end

      def schema_messages(data)
        return @items.each_with_index.map do |item, index|
          item_result = Result.new(self)
          item._validate(data, result: item_result)
          if item_result.valid?
            "  - Schema #{index + 1}: Matches"
          else
            message = "  - Schema #{index + 1}:\n"
            message << item_result.messages(pad: 4, itemize: true).join("\n")
          end
        end
      end
    end
  end
end
