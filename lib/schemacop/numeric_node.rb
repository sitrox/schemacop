module Schemacop
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
      data = super
      return if data.nil?

      # Validate minimum #
      if options[:minimum] && data < options[:minimum]
        result.error "Value must have a minimum of #{options[:minimum]}."
      end

      if options[:exclusive_minimum] && data <= options[:exclusive_minimum]
        result.error "Value must have an exclusive minimum of #{options[:exclusive_minimum]}."
      end

      # Validate maximum #
      if options[:maximum] && data > options[:maximum]
        result.error "Value must have a maximum of #{options[:maximum]}."
      end

      if options[:exclusive_maximum] && data >= options[:exclusive_maximum]
        result.error "Value must have an exclusive maximum of #{options[:exclusive_maximum]}."
      end

      # Validate multiple of #
      if options[:multiple_of] && (data % options[:multiple_of]) != 0.0
        result.error "Value must be a multiple of #{options[:multiple_of]}."
      end
    end
  end
end
