module Schemacop
  class GlobalContext < Context
    PATH = %w[config apis schemas.rb].freeze
    DSL_METHODS = %i[schema].freeze

    def self.instance
      @instance ||= new
    end

    def self.reload
      instance.reload
    end

    def self.schemas
      instance.schemas
    end

    def initialize
      super
      @schemas = {}
    end

    def reload
      @schemas = {}

      path = Rails.root.join(*PATH)

      if File.exist?(path)
        env = ScopedEnv.new(self, DSL_METHODS)
        env.instance_eval IO.read(path)
      end
    end
  end
end
