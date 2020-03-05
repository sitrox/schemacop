module Schemacop
  class Schema
    # Create a new Schema
    #
    # For detailed usage, please refer to README.md in the root of this project.
    #
    # @param args [Array] An array of arguments to apply to the root node of the
    #   Schema.
    # @param block A block with further Schema specification.
    # @raise [Schemacop::Exceptions::InvalidSchemaError] If the Schema defined
    #   is invalid.
    def initialize(*args, &block)
      @root = HashValidator.new do
        req :root, *args, &block
      end
    end

    # Query data validity
    #
    # @param data The data to validate.
    # @return [Boolean] True if the data is valid, false otherwise.
    def valid?(data)
      validate(data).valid?
    end

    # Query data validity
    #
    # @param data The data to validate.
    # @return [Boolean] True if data is invalid, false otherwise.
    def invalid?(data)
      !valid?(data)
    end

    # Validate data for the defined Schema
    #
    # @param data The data to validate.
    # @return [Schemacop::Collector] The object that collected errors
    #   throughout the validation.
    def validate(data)
      dupped_data = Schemacop::Dupper.dup_data(data)
      collector = Collector.new(dupped_data)
      @root.fields[:root].validate({ root: data }, collector.ignore_next_segment)
      return collector
    end

    # Validate data for the defined Schema
    #
    # @param data The data to validate.
    # @raise [Schemacop::Exceptions::ValidationError] If the data is invalid,
    #   this exception is thrown.
    # @return nil
    def validate!(data)
      collector = validate(data)

      unless collector.valid?
        fail Exceptions::ValidationError, collector.exception_message
      end

      return collector.data
    end
  end
end
