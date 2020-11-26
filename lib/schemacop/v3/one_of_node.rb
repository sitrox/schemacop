module Schemacop
  module V3
    class OneOfNode < CombinationNode
      def type
        :oneOf
      end

      def _validate(data, result:)
        data = super
        return if data.nil?

        matches = matches(data)

        if matches.size == 1
          matches.first._validate(data, result: result)
        else
          result.error "Matches #{matches.size} definitions but should match exactly 1."
        end
      end

      def validate_self
        if @items.size < 2
          fail 'Node one_of makes only sense with at least 2 items.'
        end
      end
    end
  end
end
