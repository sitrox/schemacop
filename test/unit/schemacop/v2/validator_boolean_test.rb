require 'test_helper'

module Schemacop
  module V2
    class ValidatorBooleanTest < V2Test
      def test_basic
        s = Schema.new do
          type :boolean
        end
        assert_nothing_raised { s.validate! true }
        assert_nothing_raised { s.validate! false }
        assert_verr { s.validate! nil }
        assert_verr { s.validate! 1 }
      end
    end
  end
end
