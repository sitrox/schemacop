require 'test_helper'

module Schemacop::V2
  class ValidatorNilTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :nil
      end
      assert_nothing_raised { s.validate! nil }
      assert_verr { s.validate! false }
    end
  end
end