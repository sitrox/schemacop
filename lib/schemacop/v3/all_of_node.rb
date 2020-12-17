module Schemacop
  module V3
    class AllOfNode < CombinationNode
      def type
        :allOf
      end

      def _validate(data, result:)
        super_data = super
        return if super_data.nil?

        if matches(super_data).size != @items.size
          result.error 'Does not match all allOf conditions.'
        end
      end

      # TODO: put back in when handling of additional keys in hashes is fixed
      # def cast(value)
      #   items = matches(value)
      #   return value unless items

      #   casted_value = value.dup

      #   items.each {|i| casted_value.merge!(i.cast(casted_value)) }
      #   return casted_value
      # end
    end
  end
end
