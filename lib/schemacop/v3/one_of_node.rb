module Schemacop
  module V3
    class OneOfNode < CombinationNode
      def type
        :oneOf
      end

      def self.allowed_options
        super + %i[treat_blank_as_nil]
      end

      def cast(value)
        item = match(value)

        unless item
          if options[:treat_blank_as_nil] && V3.blank?(value) && !value.is_a?(FalseClass)
            return nil
          else
            return value
          end
        end

        return item.cast(value)
      end

      protected

      def matches(data)
        all_matches = super
        if all_matches.size > 1
          non_wrappers = all_matches.reject(&:cast_str_wrapper?)
          return non_wrappers if non_wrappers.any?
        end
        all_matches
      end

      public

      def _validate(data, result:)
        if options[:treat_blank_as_nil] && V3.blank?(data) && !data.is_a?(FalseClass)
          data = nil
        end

        super_data = super
        return if super_data.nil?

        matches = matches(super_data)

        if matches.size == 1
          matches.first._validate(super_data, result: result)
        else
          result.error <<~PLAIN.strip
            Matches #{matches.size} schemas but should match exactly 1:
            #{schema_messages(data).join("\n")}
          PLAIN
        end
      end

      def validate_self
        if @items.size < 2
          fail 'Node "one_of" makes only sense with at least 2 items.'
        end
      end
    end
  end
end
