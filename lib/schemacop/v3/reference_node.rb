module Schemacop
  module V3
    class ReferenceNode < Node
      RFC6901_ESCAPE = { '~' => '~0', '/' => '~1' }.freeze

      def self.allowed_options
        super + %i[path]
      end

      def self.create(path, **options, &block)
        options[:path] = path
        super(**options, &block)
      end

      def as_json
        if context.swagger_json?
          # OpenAPI schema names must match ^[a-zA-Z0-9._-]+$, so we replace
          # all non-conforming characters: `/` and `~` become `.`.
          sanitized = @path.to_s.gsub(%r{[~/]}, '.')
          process_json([], '$ref': "#/components/schemas/#{sanitized}")
        else
          # Plain JSON Schema: use RFC 6901 JSON Pointer escaping in $ref.
          # gsub with a hash is a single-pass substitution, so the RFC 6901
          # order-of-escaping concern (~ before /) does not apply here.
          escaped = @path.to_s.gsub(/[~\/]/, RFC6901_ESCAPE)
          process_json([], '$ref': "#/definitions/#{escaped}")
        end
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        # Lookup schema #
        node = target
        fail "Schema #{@path.to_s.inspect} not found." unless node

        # Validate schema #
        node._validate(super_data, result: result)
      end

      def target
        schemas[@path] || Schemacop.context.schemas[@path] || GlobalContext.schema_for(@path)
      end

      def cast(data)
        data = default if data.nil?
        return target.cast(data)
      end

      def used_external_schemas(encountered_nodes = Set.new)
        if encountered_nodes.include?(self)
          return []
        end

        target_children_schema = target.used_external_schemas(encountered_nodes + [self])

        if schemas.include?(@path)
          return target_children_schema
        else
          return [@path] + target_children_schema
        end
      end

      protected

      def init
        @path = options.delete(:path)&.to_sym
      end
    end
  end
end
