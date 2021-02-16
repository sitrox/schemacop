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

    def as_json(json_format: V3::Context::DEFAULT_JSON_FORMAT)
      Schemacop.context.spawn_with(json_format: json_format) { root.as_json }
    end
  end
end
