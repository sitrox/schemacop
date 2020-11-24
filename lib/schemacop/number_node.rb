module Schemacop
  class NumberNode < NumericNode
    def as_json
      process_json(ATTRIBUTES, type: :number)
    end

    def _validate(data, result:)
      data = validate_type(data, Numeric, :number, result)

      # Super #
      super
    end
  end
end
