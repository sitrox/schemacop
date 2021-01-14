module Schemacop
  module V2
    class ArrayValidator < NodeSupportingType
      register symbols: :array, klasses: Array

      option :min # Minimal number of elements
      option :max # Maximal number of elements
      option :nil # Whether to allow nil values

      def initialize(*args)
        super
        type(:nil) if option(:nil)
      end

      def validate(data, collector)
        validate_custom_check(data, collector)

        if option?(:min) && data.size < option(:min)
          collector.error "Array must have more (>=) than #{option(:min)} elements."
        end
        if option?(:max) && data.size > option(:max)
          collector.error "Array must have less (<=) than #{option(:max)} elements."
        end
        data.each_with_index do |entry, index|
          collector.path("[#{index}]", index, :array) do
            validate_types(entry, collector)
          end
        end
      end
    end
  end
end
