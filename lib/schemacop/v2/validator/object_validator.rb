module Schemacop
  module V2
    class ObjectValidator < Node
      register symbols: :object, klasses: BasicObject

      option :classes
      option :strict

      def type_label
        "#{super} (#{classes.join(', ')})"
      end

      def type_matches?(data)
        if option(:strict).is_a?(FalseClass)
          sub_or_class = classes.map { |klass| data.class <= klass }.include?(true)
          super && (classes.empty? || sub_or_class) && !data.nil?
        else
          super && (classes.empty? || classes.include?(data.class)) && !data.nil?
        end
      end

      private

      def classes
        [*option(:classes)]
      end
    end
  end
end
