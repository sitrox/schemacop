module Schemacop
  module V3
    class ReferenceNode < Node
      def self.allowed_options
        super + %i[path type]
      end

      def self.create(path, **options, &block)
        options[:path] = path
        super(**options, &block)
      end

      def as_json
        process_json([], '$ref': "#/components/schemas/#{@path}")
      end

      def _validate(data, result:)
        data = super
        return if data.nil?

        # Lookup schema #
        node = target
        fail "Schema #{@path.to_s.inspect} not found." unless node

        # Validate schema #
        node._validate(data, result: result)
      end

      def target
        schemas[@path] || Schemacop.context.schemas[@path] || GlobalContext.schemas[@path]
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
end
