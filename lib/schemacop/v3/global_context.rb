module Schemacop
  module V3
    class GlobalContext < Context
      DSL_METHODS = %i[schema].freeze

      def self.instance
        @instance ||= new
      end

      def self.eager_load!
        instance.eager_load!
      end

      def self.schemas
        instance.schemas
      end

      def self.schema_for(path)
        instance.schema_for(path)
      end

      def schema(type = :hash, **options, &block)
        @current_schemas << Node.create(type, **options, &block)
      end

      def schema_for(path)
        path = path.to_sym
        load_schema(path) unless @eager_loaded
        @schemas[path]
      end

      def eager_load!
        @schemas = {}

        fail "Global context can't be eager loaded more than once." if @eager_loaded

        Schemacop.load_paths.each do |load_path|
          Dir.glob(File.join(load_path, '**', '*.rb')).sort.each do |file|
            load_file(file, load_path)
          end
        end

        @eager_loaded = true
      end

      private

      def initialize
        super
        @schemas = {}
        @load_paths_by_schemas = {}
        @eager_loaded = false
        @current_virtual_path = nil
      end

      def path_for(virtual_path)
        "#{virtual_path.to_s.underscore}.rb"
      end

      def virtual_path_for(path, load_path)
        Pathname.new(path).relative_path_from(load_path).to_s.underscore.gsub(/\.rb$/, '').to_sym
      end

      def load_schema(virtual_path)
        path = path_for(virtual_path)

        @schemas = schemas.except(virtual_path).freeze
        @load_paths_by_schemas = @load_paths_by_schemas.except(virtual_path)

        Schemacop.load_paths.each do |load_path|
          path_in_load_path = File.join(load_path, path)

          if File.exist?(path_in_load_path)
            load_file(path_in_load_path, load_path)
          end
        end
      end

      def load_file(path, load_path)
        return false unless File.exist?(path)

        # Determine virtual path
        virtual_path = virtual_path_for(path, load_path)

        # Run file and collect schemas
        begin
          @current_schemas = []
          env = ScopedEnv.new(self, DSL_METHODS)
          env.instance_eval File.read(path)
        rescue StandardError => e
          fail "Could not load schema #{path.inspect}: #{e.message}"
        end

        # Load schemas
        case @current_schemas.size
        when 0
          fail "Schema #{path.inspect} does not define any schema."
        when 1
          if @schemas.include?(virtual_path)
            fail "Schema #{virtual_path.to_s.inspect} is defined in both load paths " \
                 "#{@load_paths_by_schemas[virtual_path].inspect} and #{load_path.inspect}."
          end

          @load_paths_by_schemas[virtual_path] = load_path
          @schemas = @schemas.merge(virtual_path => @current_schemas.first)
        else
          fail "Schema #{path.inspect} defines multiple schemas."
        end

        return true
      end
    end
  end
end
