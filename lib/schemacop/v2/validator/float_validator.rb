module Schemacop
  module V2
    class FloatValidator < NumberValidator
      register symbols: :float, klasses: Float, before: NumberValidator
    end
  end
end
