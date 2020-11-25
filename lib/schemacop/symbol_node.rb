module Schemacop
  class SymbolNode < Node
    def as_json
      {} # Not supported by Json Schema
    end

    def allowed_types
      { Symbol => 'Symbol' }
    end
  end
end
