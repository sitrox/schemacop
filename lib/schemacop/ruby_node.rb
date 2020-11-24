module Schemacop
  class RubyNode < Node
    def self.allowed_options
      super + %i[classes]
    end

    def as_json
      {} # Not supported by Json Schema
    end

    def _validate(data, result:)
      # Validate type #
      data = validate_type(data, @classes, :ruby, result)
      return if data.nil?

      # Super #
      super
    end

    def init
      @classes = Array(options.delete(:classes) || [])
    end
  end
end
