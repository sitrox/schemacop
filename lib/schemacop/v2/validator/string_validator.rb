module Schemacop
  module V2
    class StringValidator < Node
      register symbols: :string, klasses: String

      option :min
      option :max

      def initialize(options = {})
        super(options)

        validate_options!
      end

      def validate(data, collector)
        super

        if option?(:min) && data.size < option(:min)
          collector.error "String must be longer (>=) than #{option(:min)} characters."
        end
        if option?(:max) && data.size > option(:max)
          collector.error "String must be shorter (<=) than #{option(:max)} characters."
        end
      end

      protected

      def validate_options!
        option_schema = Schema.new :integer, min: 0

        if option?(:min) && option_schema.invalid?(option(:min))
          fail Exceptions::InvalidSchemaError, 'String option :min must be an integer >= 0.'
        elsif option?(:max) && option_schema.invalid?(option(:max))
          fail Exceptions::InvalidSchemaError, 'String option :max must be an integer >= 0.'
        end
      end
    end
  end
end
