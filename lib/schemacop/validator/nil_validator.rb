module Schemacop
  class NilValidator < Node
    register symbols: :nil, klasses: NilClass
  end
end
