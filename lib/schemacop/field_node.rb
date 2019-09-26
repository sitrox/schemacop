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
        return
      end
      collector.path "/#{name}", name do
        super(data[name], collector)
      end
    end
  end
end
