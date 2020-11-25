module Schemacop
  class BooleanNode < Node
    def as_json
      process_json([], type: :boolean)
    end

    def allowed_types
      {
        TrueClass  => :boolean,
        FalseClass => :boolean
      }
    end
  end
end
