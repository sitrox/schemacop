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
    end
  end
end
