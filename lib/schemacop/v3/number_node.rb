module Schemacop
  module V3
    class NumberNode < NumericNode
      def as_json
        process_json(ATTRIBUTES, type: :number)
      end

      def allowed_types
        { Numeric => :number }
      end
    end
  end
end