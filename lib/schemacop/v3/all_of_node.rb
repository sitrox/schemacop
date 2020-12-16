module Schemacop
  module V3
    class AllOfNode < CombinationNode
      def type
        :allOf
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        if matches(super_data).size != @items.size
          result.error 'Does not match all allOf conditions.'
        end
      end
    end
  end
end
