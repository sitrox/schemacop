module Schemacop
  class AllOfNode < CombinationNode
    def type
      :allOf
    end

    def _validate(data, result:)
      return if data.nil?

      if matches(data).size != @items.size
        result.error 'Does not match any allOf condition.'
      end

      super
    end
  end
end
