module Schemacop
  module V2
    class IntegerValidator < NumberValidator
      register symbols: :integer, klasses: Integer, before: NumberValidator
    end
  end
end
