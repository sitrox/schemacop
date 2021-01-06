module Schemacop
  module V3
    class NumberNode < NumericNode
      def as_json
        process_json(ATTRIBUTES, type: :number)
      end

      def allowed_types
        {
          Integer => :integer,
          Float => :float,
          Rational => :rational,
          BigDecimal => :big_decimal
        }
      end
    end
  end
end
