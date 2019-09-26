require 'test_helper'

module Schemacop
  class ValidatorIntegerTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :integer
      end
      assert_nothing_raised { s.validate!(-3) }
      assert_nothing_raised { s.validate!(0) }
      assert_nothing_raised { s.validate!(15) }
      assert_verr { s.validate!(0.0) }
    end

    def test_option_min
      s = Schema.new do
        type :integer, min: 6
      end

      assert_nothing_raised { s.validate!(6) }
      assert_nothing_raised { s.validate!(7) }
      assert_verr { s.validate!(5) }
    end

    def test_option_max
      s = Schema.new do
        type :integer, max: 7
      end

      assert_nothing_raised { s.validate!(6) }
      assert_nothing_raised { s.validate!(7) }
      assert_verr { s.validate!(8) }
    end

    def test_options_min_max
      s = Schema.new do
        type :integer, min: 6, max: 7
      end

      assert_nothing_raised { s.validate!(6) }
      assert_nothing_raised { s.validate!(7) }
      assert_verr { s.validate!(5) }
      assert_verr { s.validate!(8) }
    end
  end
end
