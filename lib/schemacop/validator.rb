module Schemacop
  class Validator
    TYPE_ALIASES = {
      hash:             [Hash],
      array:            [Array],
      string:           [String],
      integer:          [Integer],
      boolean:          [TrueClass, FalseClass]
    }

    # Validates `data` against `schema` and throws an exception on missmatch.
    #
    # @param [Hash] schema The schema to validate against
    # @param [Object] data The data to validate
    # @return [void]
    def self.validate!(schema, data)
      new(schema, data)
      return nil
    end

    private

    def initialize(schema, data)
      validate_branch '', schema, data
    end

    def prepare_schema(schema)
      schema = { types: schema } unless schema.is_a? Hash

      if schema.include?(:type)
        schema[:types] = schema.delete :type
      else
        schema[:types] = :array unless schema[:array].nil?
        schema[:types] = :hash  unless schema[:hash].nil?
      end

      schema[:types] = [*schema[:types]]
      schema[:types].each do |type|
        if type == :hash
          if schema.include? :fields
            schema[:hash] = schema.delete :fields
          end

          if schema[type].is_a? Hash
            schema[type].each do |key, value|
              schema[type][key] = prepare_schema value
            end
          end
        end

        if type == :array
          schema[:array] = prepare_schema schema[:array]
        end
      end

      schema
    end

    def assign_data_type(type)
      if type.is_a? Symbol
        fail Exceptions::InvalidSchema, "Type alias #{type} is not supported." if TYPE_ALIASES[type].nil?
        TYPE_ALIASES[type]
      elsif type.is_a? String
        type.to_s.classify.safe_constantize
      else
        type
      end
    end

    def validate_branch(path, schema, data)
      schema = prepare_schema(schema)

      # ---------------------------------------------------------------
      # Type validation
      # ---------------------------------------------------------------
      supported_types = schema[:types].map { |type| assign_data_type type }.flatten

      # ---------------------------------------------------------------
      # Check root path rules
      # ---------------------------------------------------------------
      if path.empty?
        supported_types << NilClass if schema[:null] == true

        if schema.include? :require
          fail Exceptions::InvalidSchema, "The :require property can't be used on top level of schema."
        end
      end

      unless supported_types.any? { |t| data.is_a?(t) }
        fail Exceptions::Validation, "Property at path #{path} must be of type #{supported_types.inspect}."
      end

      # ---------------------------------------------------------------
      # Check for allowed values
      # ---------------------------------------------------------------
      if schema[:allowed_values] && !schema[:allowed_values].include?(data)
        fail Exceptions::Validation,
             "Value #{data.inspect} of property at path #{path} is not valid. Valid are: #{schema[:allowed_values].inspect}."
      end

      # ---------------------------------------------------------------
      # Validate children
      # ---------------------------------------------------------------
      if data.is_a?(Hash)
        data = HashWithIndifferentAccess.new data

        unless schema.include? :hash
          fail Exceptions::InvalidSchema, "Missing schema entry :hash at path #{path}."
        end

        data_keys = data.keys.collect(&:to_s)
        schema_keys = schema[:hash].keys.collect(&:to_s)

        unless (obsolete_keys = data_keys - schema_keys).empty?
          fail Exceptions::Validation, "Obsolete keys at path #{path}: #{obsolete_keys.inspect}."
        end

        schema[:hash].each do |sub_key, sub_schema|
          if sub_schema[:required] != false && !data.include?(sub_key)
            fail Exceptions::Validation, "Missing property at path #{path}.#{sub_key}."
          end

          if data[sub_key].nil?
            unless sub_schema[:null] == true
              fail Exceptions::Validation, "Property at path #{path}.#{sub_key} can't be null."
            end
          else
            validate_branch "#{path}.#{sub_key}", sub_schema, data[sub_key]
          end
        end
      elsif schema[:types].include? :array
        data.each_with_index do |value, index|
          validate_branch "#{path}[#{index}]", schema[:array], value
        end
      end
    end
  end
end
