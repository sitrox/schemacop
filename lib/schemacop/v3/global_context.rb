module Schemacop
  module V3
    # TODO: Cache schemas in development mode and load only what's necessary
    class GlobalContext < Context
      DSL_METHODS = %i[schema].freeze

      def self.available?
        defined?(Rails)
      end

      def self.instance
        @instance ||= new
      end

      def self.reload
        instance.reload
      end

      def self.reload!
        instance.reload!
      end

      def self.schemas
        instance.reload
        instance.schemas
      end

      def reload
        reload! if self.class.available? && Rails.env.development?
      end

      def reload!
        @schemas = {}

        return unless self.class.available?

        Schemacop.load_paths.each do |load_path|
          Dir.glob(Rails.root.join(load_path, '**', '*.rb')).each do |file|
            load_file file
          end
        end
      end

      private

      def initialize
        super
        @schemas = {}
      end

      def load_file(path)
        env = ScopedEnv.new(self, DSL_METHODS)
        env.instance_eval IO.read(path)
      end
    end
  end
end
