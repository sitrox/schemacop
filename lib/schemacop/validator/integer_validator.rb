module Schemacop
  class IntegerValidator < NumberValidator
    register symbols: :integer, klasses: Integer
  end
end
