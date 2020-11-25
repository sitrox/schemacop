module Schemacop
  class BaseSchema
    attr_reader :root

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
    # @raise [Schemacop::Exceptions::ValidationError] If the data is invalid,
    #   this exception is thrown.
    # @return The processed data
    def validate!(data)
      result = validate(data)

      unless result.valid?
        fail Exceptions::ValidationError, result.exception_message
      end

      return result.data
    end
  end
end
