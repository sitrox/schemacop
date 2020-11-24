module Schemacop::V2
  class NumberValidator < Node
    register symbols: :number, klasses: [Integer, Float]

    option :min
    option :max

    def validate(data, collector)
      super

      if option?(:min) && data < option(:min)
        collector.error "Value must be >= #{option(:min)}."
      end
      if option?(:max) && data > option(:max)
        collector.error "Value must be <= #{option(:max)}."
      end
    end
  end
end
