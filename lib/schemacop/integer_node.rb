module Schemacop
  class IntegerNode < NumericNode
    def as_json
      process_json(ATTRIBUTES, type: :integer)
    end

    def allowed_types
      { Integer => :integer }
    end
  end
end
