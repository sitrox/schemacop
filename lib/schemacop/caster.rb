module Schemacop
  class Caster
    def initialize(casts, data, target_type)
      @casts = casts
      @data = data
      @target_type = target_type
      @caster = nil

      if casts.is_a?(Array)
        from_types = casts
      elsif casts.is_a?(Hash)
        from_types = casts.keys
      else
        fail Exceptions::InvalidSchemaError, "Option `cast` must be either an array or a hash."
      end

      return unless from_types.include?(data.class)

      if (casts.is_a?(Array) && casts.include?(data.class)) || casts[data.class] == :default
        @caster = DEFAULT_CASTERS[data.class][target_type]
      else
        @caster = casts[data.class]
      end
    end

    def castable?
      !@caster.nil?
    end

    def cast
      fail 'Not castable.' unless castable?
      return @caster.call(@data)
    rescue => e
      fail Exceptions::InvalidSchemaError,
           "Could not cast value #{@value.inspect} to #{@target_type}: #{e.message}."
    end
  end
end
