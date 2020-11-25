module Schemacop
  module V3
    class DslScope
      EXP_NAME = /^dsl_([a-z_]+)([?!])?$/.freeze

      def initialize(node)
        @node = node
        @with_name = @node.class.supports_children_options[:name]
      end

      def method_missing(name, *args, **options, &block)
        match = EXP_NAME.match(name)
        return super unless match
        base_name, req_optional = match.captures

        if req_optional == '!'
          options[:required] = true
        elsif req_optional == '?'
          options[:required] = false
        end

        options[:parent] = @node

        if (klass = NodeRegistry.by_short_name(base_name))
          if @with_name
            options[:name] = args.shift
          end
          node = klass.create(*args, **options, &block)
          @node.add_child node
          return node
        else
          return super
        end
      end

      def respond_to_missing?(name, *args)
        match = EXP_NAME.match(name)
        return super unless match
        base_name, _req_optional = match.captures
        return NodeRegistry.by_short_name(base_name).present? || super
      end
    end
  end
end
