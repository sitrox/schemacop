module Schemacop
  module V3
    class Context
      attr_accessor :schemas
      attr_accessor :examples_keyword

      DEFAULT_EXAMPLES_KEYWORD = :examples

      def initialize
        @schemas = {}.with_indifferent_access.freeze
        @examples_keyword = DEFAULT_EXAMPLES_KEYWORD
      end

      def schema(name, type = :hash, **options, &block)
        @schemas = @schemas.merge(
          name => Node.create(type, **options, &block)
        ).freeze
      end
    end
  end
end
