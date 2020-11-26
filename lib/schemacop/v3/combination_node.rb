module Schemacop
  module V3
    # @abstract
    class CombinationNode < Node
      def self.dsl_methods
        # TODO: Do we need dsl_add_item?
        super + NodeRegistry.dsl_methods(false) + %i[dsl_add_item]
      end

      supports_children

      def init
        @items = []
      end

      def dsl_add_item(node)
        add_child node
      end

      def as_json
        process_json([], type => @items.map(&:as_json))
      end

      def cast(value)
        item = match(value)
        return value unless item
        return item.cast(value)
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
        @items.filter { |i| item_matches?(i, data) }
      end
    end
  end
end
