module Schemacop::V2
  class BooleanValidator < Node
    register symbols: :boolean, klasses: [TrueClass, FalseClass]
  end
end
