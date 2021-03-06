require 'test_helper'

module Schemacop
  module V2
    class CustomCheckTest < V2Test
      def test_integer_check_short_form
        s = Schema.new :integer, check: proc { |i| i.even? }
        assert_nothing_raised { s.validate!(2) }
        assert_nothing_raised { s.validate!(-8) }
        assert_nothing_raised { s.validate!(0) }
        assert_verr { s.validate!(1) }
        assert_verr { s.validate!(-7) }
        assert_verr { s.validate!(2.1) }
      end

      def test_custom_error_message
        s = Schema.new :integer, check: proc { |i| i.even? ? true : 'Custom error' }
        assert_nothing_raised { s.validate!(2) }
        exception = assert_verr { s.validate!(3) }
        assert_match(/Custom :check failed: Custom error\./, exception.message)
      end

      def test_integer_check_with_lambda
        s = Schema.new do
          type :integer, check: ->(i) { i.even? }
        end

        assert_nothing_raised { s.validate!(2) }
        assert_nothing_raised { s.validate!(-8) }
        assert_nothing_raised { s.validate!(0) }
        assert_verr { s.validate!(1) }
        assert_verr { s.validate!(-7) }
        assert_verr { s.validate!(2.1) }
      end

      def test_in_type_dsl
        s = Schema.new do
          type :number, check: proc { |x| x == 42 }
        end
        assert_nothing_raised { s.validate!(42) }
        assert_verr { s.validate!(42.1) }
        assert_verr { s.validate!(0) }
      end

      def test_with_array
        s = Schema.new do
          type :array, check: proc { |a| a.first == 1 } do
            type :integer
          end
        end
        assert_nothing_raised { s.validate!([1, 2, 3]) }
        assert_verr { s.validate!([2, 3, 4]) }
      end

      def test_with_array_nested
        s = Schema.new do
          type :array, check: proc { |a| a.first == 4 } do
            type :integer, check: proc { |i| i >= 2 }
          end
        end

        assert_nothing_raised { s.validate!([4, 3, 2]) }
        assert_verr { s.validate!([3, 2]) }
        assert_verr { s.validate!([4, 1]) }
      end

      def test_with_hash
        s = Schema.new :hash, check: proc { |h| h.all? { |k, v| k == v } } do
          opt 1, :integer
          opt 'two', :string
        end
        assert_nothing_raised { s.validate!(1 => 1, 'two' => 'two') }
        assert_verr { s.validate!(1 => 2, 'two' => 'two') }
        assert_verr { s.validate!(1 => 1, 'two' => 'one') }
      end

      def test_mixed_if_check
        s = Schema.new do
          req :first_name,
              :string,
              if:    proc { |str| str.start_with?('Sand') },
              check: proc { |str| str == 'Sandy' }
          req :first_name, :string, min: 3
        end

        assert_nothing_raised { s.validate!(first_name: 'Bob') }
        assert_nothing_raised { s.validate!(first_name: 'Sandy') }
        assert_nothing_raised { s.validate!(first_name: 'Sansibar') }

        assert_verr { s.validate!(first_name: 'Sandkasten') }
        assert_verr { s.validate!(first_name: 'a') }
      end
    end
  end
end
