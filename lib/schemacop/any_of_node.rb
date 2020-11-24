module Schemacop
  class AnyOfNode < CombinationNode
    def type
      :anyOf
    end

    def _validate(data, result:)
      return if data.nil?

      match = match(data)

      if match
        match._validate(data, result: result)
      else
        result.error 'Does not match any anyOf condition.'
      end

      super
    end
  end
end
