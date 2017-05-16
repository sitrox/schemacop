require 'test_helper'

module Schemacop
  class ValidatorSymbolTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :symbol
      end

      assert_nil s.validate!(:good)
      assert_nil s.validate!('-+/'.to_sym)
      assert_verr { s.validate!('bad') }
      assert_verr { s.validate!(456) }
    end
  end
end
