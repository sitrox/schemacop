module Schemacop
  class AllOfNode < CombinationNode
    def type
      :allOf
    end

    def _validate(data, result:)
      data = super
      return if data.nil?

      if matches(data).size != @items.size
        result.error 'Does not match any allOf condition.'
      end
    end
  end
end
