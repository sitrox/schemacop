module Schemacop
  module V3
    # @abstract
    class NumericNode < Node
      ATTRIBUTES = %i[
        minimum
        exclusive_minimum
        maximum
        exclusive_maximum
        multiple_of
      ].freeze

      def self.allowed_options
        super + ATTRIBUTES
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        # Validate minimum #
        if options[:minimum] && super_data < options[:minimum]
          result.error "Value must have a minimum of #{options[:minimum]}."
        end

        if options[:exclusive_minimum] && super_data <= options[:exclusive_minimum]
          result.error "Value must have an exclusive minimum of #{options[:exclusive_minimum]}."
        end

        # Validate maximum #
        if options[:maximum] && super_data > options[:maximum]
          result.error "Value must have a maximum of #{options[:maximum]}."
        end

        if options[:exclusive_maximum] && super_data >= options[:exclusive_maximum]
          result.error "Value must have an exclusive maximum of #{options[:exclusive_maximum]}."
        end

        # Validate multiple of #
        if options[:multiple_of] && !compare_float((super_data % options[:multiple_of]), 0.0)
          result.error "Value must be a multiple of #{options[:multiple_of]}."
        end
      end

      def validate_self
        if options[:minimum] && options[:maximum] && options[:minimum] > options[:maximum]
          fail 'Option "minimum" can\'t be greater than "maximum".'
        end

        if options[:exclusive_minimum] && options[:exclusive_maximum]\
           && options[:exclusive_minimum] > options[:exclusive_maximum]
          fail 'Option "exclusive_minimum" can\'t be greater than "exclusive_maximum".'
        end

        if options[:multiple_of]&.zero?
          fail 'Option "multiple_of" can\'t be 0.'
        end
      end

      private

      def compare_float(first, second)
        (first - second).abs < Float::EPSILON
      end
    end
  end
end
