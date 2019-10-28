module Schemacop
  class FieldNode < NodeSupportingType
    attr_reader :name

    def initialize(name, required, options = {}, &block)
      if options.any?
        fail Exceptions::InvalidSchemaError, 'Node does not support options.'
      end

      super({}, &block)

      @name = name
      @required = required
    end

    def validate(data, collector)
      unless data.key?(name)
        collector.error "Missing key #{name.inspect}." if @required
      end

      collector.path "/#{name}", name, :hash do
        value, default_applied = apply_default!(data[name], collector)

        unless data.key?(name) || default_applied
          next
        end

        super(value, collector)
      end
    end

    private

    def apply_default!(data, collector)
      return data, false unless data.nil?

      @types.each do |type|
        next unless type.option?(:default)
        default = type.option(:default)
        collector.override_value(default)
        return default, true
      end

      return nil, false
    end
  end
end
