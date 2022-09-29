module Schemacop
  module V3
    class AllOfNode < CombinationNode
      def type
        :allOf
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        matches = matches(super_data)

        if matches.size != @items.size
          result.error <<~PLAIN.strip
            Matches #{matches.size} schemas but should match all of them:
            #{schema_messages(data).join("\n")}
          PLAIN
        end
      end

      def cast(value)
        items = matches(value)
        return value unless items

        casted_value = value.dup
        items.each { |i| casted_value = i.cast(casted_value) }
        return casted_value
      end
    end
  end
end
