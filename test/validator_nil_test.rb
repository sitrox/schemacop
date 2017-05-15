require 'test_helper'

module Schemacop
  class ValidatorNilTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :nil
      end
      assert_nil s.validate! nil
      assert_verr { s.validate! false }
    end
  end
end
