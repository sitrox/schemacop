module Schemacop
  module V3
    class NodeRegistry
      @by_name = {}
      @by_short_name = {}
      @by_class = {}

      def self.register(name, short_name, klass)
        @by_name[name.to_sym] = klass
        @by_short_name[short_name.to_sym] = klass
        @by_class[klass] = { name: name.to_sym, short_name: short_name.to_sym }
      end

      def self.dsl_methods(bang)
        return @by_short_name.keys.map do |short_name|
          if bang
            ["dsl_#{short_name}!", "dsl_#{short_name}?"]
          else
            ["dsl_#{short_name}"]
          end
        end.flatten.map(&:to_sym)
      end

      def self.find(name_or_klass)
        if name_or_klass.is_a?(Class)
          return name_or_klass
        else
          return by_name(name_or_klass)
        end
      end

      def self.by_name(name)
        @by_name[name.to_sym]
      end

      def self.by_short_name(short_name)
        @by_short_name[short_name.to_sym]
      end

      def self.name(klass)
        @by_class[klass][:name]
      end

      def self.short_name(klass)
        @by_class[klass][:short_name]
      end
    end
  end
end
