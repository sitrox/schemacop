module Schemacop
  class OneOfNode < CombinationNode
    def type
      :oneOf
    end

    def _validate(data, result:)
      data = super
      return if data.nil?

      matches = matches(data)

      if matches.size == 1
        matches.first._validate(data, result: result)
      else
        result.error "Matches #{matches.size} definitions but should match exactly 1."
      end
    end
  end
end
