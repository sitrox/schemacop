module Schemacop
  class Schema2 < BaseSchema
    def initialize(*args, **kwargs, &block)
      super()
      @root = V2::HashValidator.new do
        req :root, *args, **kwargs, &block
      end
    end

    # Validate data for the defined Schema
    #
    # @param data The data to validate.
    # @return [Schemacop::Collector] The object that collected errors
    #   throughout the validation.
    def validate(data)
      dupped_data = V2::Dupper.dup_data(data)
      collector = V2::Collector.new(dupped_data)
      root.fields[:root].validate({ root: data }, collector.ignore_next_segment)
      return collector
    end
  end
end
