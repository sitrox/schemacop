module Schemacop
  class IntegerNode < NumericNode
    def as_json
      process_json(ATTRIBUTES, type: :integer)
    end

    def _validate(data, result:)
      # Validate type #
      data = validate_type(data, Integer, :integer, result)
      return if data.nil?

      # Super #
      super
    end
  end
end
