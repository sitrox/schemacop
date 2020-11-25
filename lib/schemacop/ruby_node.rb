module Schemacop
  class RubyNode < Node
    def self.allowed_options
      super + %i[classes]
    end

    def self.create(classes, **options, &block)
      options[:classes] = classes
      super(**options, &block)
    end

    def as_json
      {} # Not supported by Json Schema
    end

    def allowed_types
      Hash[@classes.map { |c| [c, c.name] }]
    end

    def init
      @classes = Array(options.delete(:classes) || [])
    end
  end
end
