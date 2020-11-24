require 'test_helper'

module Schemacop::V2
  class ValidatorNumberTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :number
      end
      assert_nothing_raised { s.validate!(-3) }
      assert_nothing_raised { s.validate!(-3.123) }
      assert_nothing_raised { s.validate!(0) }
      assert_nothing_raised { s.validate!(15) }
      assert_nothing_raised { s.validate!(15.13) }
      assert_verr { s.validate!('0.12') }
    end

    def test_option_min
      s = Schema.new do
        type :number, min: -2
      end

      assert_nothing_raised { s.validate!(-2) }
      assert_nothing_raised { s.validate!(-1.99999) }
      assert_nothing_raised { s.validate!(0) }
      assert_nothing_raised { s.validate!(1.2) }
      assert_verr { s.validate!(-3) }
      assert_verr { s.validate!(-2.00001) }
    end

    def test_option_max
      s = Schema.new do
        type :number, max: 5.2
      end

      assert_nothing_raised { s.validate!(-2) }
      assert_nothing_raised { s.validate!(-1.9) }
      assert_nothing_raised { s.validate!(0) }
      assert_nothing_raised { s.validate!(5.19999) }
      assert_nothing_raised { s.validate!(5.2) }
      assert_verr { s.validate!(5.200001) }
      assert_verr { s.validate!(6) }
    end

    def test_options_min_max
      s = Schema.new do
        type :number, min: -2, max: 5.2
      end

      assert_nothing_raised { s.validate!(-2) }
      assert_nothing_raised { s.validate!(-1.99999) }
      assert_nothing_raised { s.validate!(0) }
      assert_nothing_raised { s.validate!(1.2) }
      assert_nothing_raised { s.validate!(5.2) }
      assert_verr { s.validate!(-3) }
      assert_verr { s.validate!(-2.00001) }
      assert_verr { s.validate!(5.200001) }
      assert_verr { s.validate!(6) }
    end
  end
end
