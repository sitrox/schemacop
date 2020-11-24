require 'test_helper'

module Schemacop::V2
  class ValidatorBooleanTest < Minitest::Test
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
