module Schemacop
  class ReferenceNode < Node
    def self.allowed_options
      super + %i[path type]
    end

    def as_json
      process_json([], '$ref': "#/components/schemas/#{@path}")
    end

    def _validate(data, result:)
      # Lookup schema #
      node = target
      fail "Schema #{@path.to_s.inspect} not found." unless node

      # Validate schema #
      node._validate(data, result: result)

      # Super #
      super
    end

    def target
      schemas[@path] || Schemacop.context.schemas[@path] || Schemacop::GlobalContext.schemas[@path]
    end

    def cast(data)
      data = default if data.nil?
      return target.cast(data)
    end

    def used_external_schemas
      schemas.include?(@path) ? [] : [@path]
    end

    protected

    def init
      @path = options.delete(:path)
    end
  end
end
