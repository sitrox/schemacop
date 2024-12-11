module Schemacop
  module V3
    class ReferenceNode < Node
      def self.allowed_options
        super + %i[path]
      end

      def self.create(path, **options, &block)
        options[:path] = path
        super(**options, &block)
      end

      def as_json
        if context.swagger_json?
          process_json([], '$ref': "#/components/schemas/#{@path}")
        else
          process_json([], '$ref': "#/definitions/#{@path}")
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
        @path = options.delete(:path)
      end
    end
  end
end
