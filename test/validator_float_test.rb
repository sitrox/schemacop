require 'test_helper'

module Schemacop
  class ValidatorFloatTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :float
      end
      assert_nil s.validate!(-3.0)
      assert_nil s.validate!(-3.123)
      assert_nil s.validate!(0.0)
      assert_nil s.validate!(15.0)
      assert_nil s.validate!(15.13)
      assert_verr { s.validate!(-3) }
      assert_verr { s.validate!(0) }
      assert_verr { s.validate!(15) }
    end

    def test_option_min
      s = Schema.new do
        type :float, min: -2
      end

      assert_nil s.validate!(-2.0)
      assert_nil s.validate!(-1.99999)
      assert_nil s.validate!(1.2)
      assert_verr { s.validate!(-5.2) }
      assert_verr { s.validate!(-2.00001) }
    end

    def test_option_max
      s = Schema.new do
        type :float, max: 5.2
      end

      assert_nil s.validate!(-2.0)
      assert_nil s.validate!(5.2)
      assert_verr { s.validate!(5.200001) }
    end

    def test_options_min_max
      s = Schema.new do
        type :float, min: -2, max: 5.2
      end

      assert_nil s.validate!(-2.0)
      assert_nil s.validate!(-1.99999)
      assert_nil s.validate!(0.0)
      assert_nil s.validate!(1.2)
      assert_nil s.validate!(5.2)
      assert_verr { s.validate!(-2.00001) }
      assert_verr { s.validate!(5.200001) }
      assert_verr { s.validate!(6) }
      assert_verr { s.validate!(0) }
    end
  end
end
