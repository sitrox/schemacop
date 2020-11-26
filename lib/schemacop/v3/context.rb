module Schemacop
  module V3
    class Context
      attr_accessor :schemas

      def initialize
        @schemas = {}.with_indifferent_access.freeze
      end

      def schema(name, type = :hash, **options, &block)
        @schemas = @schemas.merge(
          name => Node.create(type, **options, &block)
        ).freeze
      end
    end
  end
end
