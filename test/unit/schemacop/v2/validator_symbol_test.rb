require 'test_helper'

module Schemacop
  module V2
    class ValidatorSymbolTest < V2Test
      def test_basic
        s = Schema.new do
          type :symbol
        end

        assert_nothing_raised { s.validate!(:good) }
        assert_nothing_raised { s.validate!(:'-+/') }
        assert_verr { s.validate!('bad') }
        assert_verr { s.validate!(456) }
      end
    end
  end
end
