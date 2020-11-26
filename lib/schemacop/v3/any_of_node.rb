module Schemacop
  module V3
    class AnyOfNode < CombinationNode
      def type
        :anyOf
      end

      def _validate(data, result:)
        data = super
        return if data.nil?

        match = match(data)

        if match
          match._validate(data, result: result)
        else
          result.error 'Does not match any anyOf condition.'
        end
      end

      def validate_self
        if @items.size < 1
          binding.pry
          fail 'Node any_of makes only sense with at least 1 item.'
        end
      end
    end
  end
end
