module Schemacop
  class Context
    attr_accessor :schemas

    def initialize
      @schemas = {}.freeze
    end

    def schema(name, type = :hash, **options, &block)
      @schemas = @schemas.merge(
        name => Schemacop::Node.create(type, **options, &block)
      ).freeze
    end
  end
end
