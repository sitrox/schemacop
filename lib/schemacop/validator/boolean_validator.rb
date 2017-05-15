module Schemacop
  class BooleanValidator < Node
    register symbols: :boolean, klasses: [TrueClass, FalseClass]
  end
end
