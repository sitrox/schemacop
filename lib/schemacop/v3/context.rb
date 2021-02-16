module Schemacop
  module V3
    class Context
      attr_accessor :schemas
      attr_accessor :json_format

      DEFAULT_JSON_FORMAT = :default

      def initialize(json_format: DEFAULT_JSON_FORMAT)
        @schemas = {}.with_indifferent_access.freeze
        @json_format = json_format
      end

      def schema(name, type = :hash, **options, &block)
        @schemas = @schemas.merge(
          name => Node.create(type, **options, &block)
        ).freeze
      end

      def spawn_with(json_format: @json_format)
        prev_json_format = @json_format
        @json_format = json_format
        return yield
      ensure
        @json_format = prev_json_format
      end

      def swagger_json?
        @json_format == :swagger
      end
    end
  end
end
