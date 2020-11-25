module Schemacop
  class Schema
    attr_reader :version

    def initialize(*args, &block)
      # Determine version #
      if args.first && /^v[0-9]$/.match?(args.first.to_s)
        @version = /^v([0-9])$/.match(args.pop.to_s).captures[1].to_i
      else
        @version = Schemacop.default_schema_version
      end

      if version == 3
        @root = Schemacop::Node.create(*args, &block)
      elsif version == 2
        @root = V2::HashValidator.new do
          req :root, *args, &block
        end
      else
        fail "Unsupported schema version #{version}. Schemacop supports 2 and 3."
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
      if version == 3
        @root.validate(data)
      elsif version == 2
        dupped_data = V2::Dupper.dup_data(data)
        collector = V2::Collector.new(dupped_data)
        @root.fields[:root].validate({ root: data }, collector.ignore_next_segment)
        return collector
      end
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
        if version == 3
          fail Exceptions::ValidationError, result.messages
        elsif version == 2
          fail Exceptions::ValidationError, result.exception_message
        end
      end

      return result.data
    end
  end
end
