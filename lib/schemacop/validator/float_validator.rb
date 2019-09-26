module Schemacop
  class FloatValidator < NumberValidator
    register symbols: :float, klasses: Float, before: NumberValidator
  end
end
