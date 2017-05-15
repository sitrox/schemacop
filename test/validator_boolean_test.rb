require 'test_helper'

module Schemacop
  class ValidatorBooleanTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :boolean
      end
      assert_nil s.validate! true
      assert_nil s.validate! false
      assert_verr { s.validate! nil }
      assert_verr { s.validate! 1 }
    end
  end
end
