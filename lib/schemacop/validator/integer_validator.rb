module Schemacop
  class IntegerValidator < NumberValidator
    register symbols: :integer, klasses: Integer, before: NumberValidator
  end
end
