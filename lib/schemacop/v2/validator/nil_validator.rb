module Schemacop::V2
  class NilValidator < Node
    register symbols: :nil, klasses: NilClass
  end
end
