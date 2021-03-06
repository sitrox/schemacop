module Schemacop
  module V3
    class IsNotNode < CombinationNode
      def type
        :not
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        if matches(super_data).any?
          result.error "Must not match schema: #{@items.first.as_json.as_json.inspect}."
        end
      end

      def as_json
        process_json([], type => @items.first.as_json)
      end

      def validate_self
        if @items.count != 1
          fail 'Node "is_not" only allows exactly one item.'
        end
      end

      def cast(data)
        data
      end
    end
  end
end
