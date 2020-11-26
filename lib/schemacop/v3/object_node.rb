module Schemacop
  module V3
    class ObjectNode < Node
      def self.allowed_options
        super + %i[classes strict]
      end

      def self.create(classes, **options, &block)
        options[:classes] = classes
        super(**options, &block)
      end

      def as_json
        {} # Not supported by Json Schema
      end

      protected

      def allowed_types
        Hash[@classes.map { |c| [c, c.name] }]
      end

      def init
        @classes = Array(options.delete(:classes) || [])
        @strict = options.delete(:strict)
        @strict = true if @strict.nil?
      end

      def type_assertion_method
        @strict ? :instance_of? : :is_a?
      end
    end
  end
end
