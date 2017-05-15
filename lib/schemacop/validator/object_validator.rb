module Schemacop
  class ObjectValidator < Node
    register symbols: :object, klasses: Object

    option :classes

    def type_label
      "#{super} (#{classes.join(', ')})"
    end

    def type_matches?(data)
      super && (classes.empty? || classes.include?(data.class)) && !data.nil?
    end

    private

    def classes
      [*option(:classes)]
    end
  end
end
