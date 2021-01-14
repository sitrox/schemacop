require 'test_helper'

module Schemacop
  module V2
    class ValidatorStringTest < V2Test
      def test_basic
        s = Schema.new do
          type :string
        end
        assert_nothing_raised { s.validate! '' }
        assert_nothing_raised { s.validate! 'abc' }
        assert_nothing_raised { s.validate! 123.to_s }
        assert_nothing_raised { s.validate! inspect }
      end

      def test_option_min
        s = Schema.new do
          type :string, min: 3
        end

        assert_nothing_raised { s.validate!('abc') }
        assert_nothing_raised { s.validate!('abcd') }
        assert_verr { s.validate!('ab') }
        assert_verr { s.validate!('') }
      end

      def test_option_max
        s = Schema.new do
          type :string, max: 5
        end

        assert_nothing_raised { s.validate!('') }
        assert_nothing_raised { s.validate!('abcd') }
        assert_nothing_raised { s.validate!('abcde') }
        assert_verr { s.validate!('abcdef') }
      end

      def test_options_min_max
        s = Schema.new do
          type :string, min: 3, max: 5
        end

        assert_nothing_raised { s.validate!('abc') }
        assert_nothing_raised { s.validate!('abcd') }
        assert_nothing_raised { s.validate!('abcde') }
        assert_verr { s.validate!('ab') }
        assert_verr { s.validate!('abcdef') }
        assert_verr { s.validate!('') }
      end

      def test_float_options
        assert_raises Exceptions::InvalidSchemaError, 'String option :min must be an integer >= 0.' do
          Schema.new do
            type :string, min: 3.2
          end
        end

        assert_raises Exceptions::InvalidSchemaError, 'String option :max must be an integer >= 0.' do
          Schema.new do
            type :string, max: 5.2
          end
        end

        assert_raises Exceptions::InvalidSchemaError, 'String option :min must be an integer >= 0.' do
          Schema.new do
            type :string, min: 3.2, max: 5
          end
        end

        assert_raises Exceptions::InvalidSchemaError, 'String option :max must be an integer >= 0.' do
          Schema.new do
            type :string, min: 3, max: 5.2
          end
        end
      end
    end
  end
end
