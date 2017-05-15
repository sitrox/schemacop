module Schemacop
  class FloatValidator < NumberValidator
    register symbols: :float, klasses: Float
  end
end
