module Schemacop
  module V3
    class AnyOfNode < CombinationNode
      def type
        :anyOf
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        match = match(super_data)

        if match
          match._validate(super_data, result: result)
        else
          result.error <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
            #{schema_messages(super_data).join("\n")}
          PLAIN
        end
      end

      def validate_self
        if @items.empty?
          fail 'Node "any_of" makes only sense with at least 1 item.'
        end
      end
    end
  end
end
