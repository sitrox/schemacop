module Schemacop
  class SymbolNode < Node
    def as_json
      {} # Not supported by Json Schema
    end

    def _validate(data, result:)
      # Validate type #
      data = validate_type(data, [Symbol], :symbol, result)
      return if data.nil?

      # Super #
      super
    end
  end
end
