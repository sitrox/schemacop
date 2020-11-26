module Schemacop
  class Schema3 < BaseSchema
    def initialize(*args, &block)
      @root = V3::Node.create(*args, &block)
    end

    # Validate data for the defined Schema
    #
    # @param data The data to validate.
    # @return [Schemacop::Collector] The object that collected errors
    #   throughout the validation.
    def validate(data)
      root.validate(data)
    end
  end
end
