module Schemacop
  class Schema3 < BaseSchema
    def initialize(*args, **kwargs, &block)
      super()
      @root = V3::Node.create(*args, **kwargs, &block)
    end

    # Validate data for the defined Schema
    #
    # @param data The data to validate.
    # @return [Schemacop::Collector] The object that collected errors
    #   throughout the validation.
    def validate(data)
      root.validate(data)
    end

    def as_json
      root.as_json
    end
  end
end
