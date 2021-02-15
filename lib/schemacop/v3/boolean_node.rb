module Schemacop
  module V3
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

      def cast(value)
        if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          value
        else
          default
        end
      end
    end
  end
end
