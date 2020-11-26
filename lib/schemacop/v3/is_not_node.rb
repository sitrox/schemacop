module Schemacop
  module V3
    class IsNotNode < CombinationNode
      def type
        :not
      end

      def add_item(node)
        if @items.any?
          fail 'Node is_not only allows exactly one item.'
        end

        @items << node
      end

      def _validate(data, result:)
        data = super
        return if data.nil?

        if matches(data).any?
          result.error "Must not match schema: #{@items.first.as_json.as_json.inspect}."
        end
      end

      def validate_self
        if @items.size < 1
          binding.pry
          fail 'Node is_not makes only sense with at least 1 item.'
        end
      end

      def cast(data)
        data
      end
    end
  end
end
