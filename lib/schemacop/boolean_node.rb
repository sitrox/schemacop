module Schemacop
  class BooleanNode < Node
    def as_json
      process_json([], type: :boolean)
    end

    def _validate(data, result:)
      # Validate type #
      data = validate_type(data, [TrueClass, FalseClass], :boolean, result)
      return if data.nil?

      # Super #
      super
    end
  end
end
