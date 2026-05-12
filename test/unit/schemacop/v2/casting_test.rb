require 'test_helper'

module Schemacop
  module V2
    class CastingTest < V2Test
      def test_basic
        s = Schema.new :integer, cast: [String]

        input = '42'
        output = s.validate!(input)

        assert_equal(42, output)
      end

      def test_field
        s = Schema.new do
          req :foo, :integer, cast: [String]
        end

        input = { foo: '42' }
        output = s.validate!(input)

        assert_equal({ foo: '42' }, input)
        assert_equal({ foo: 42 }, output)
      end

      def test_first_type_matches
        s = Schema.new do
          type TrueClass
          type :integer, cast: [String]
        end

        assert_equal(42, s.validate!('42'))
        assert_equal(42, s.validate!(42))
        assert_equal(true, s.validate!(true))
      end

      def test_with_if
        s = Schema.new do
          type Float, if: proc { |data| !data.is_a?(String) || data.match(/\d+\.\d+/) }, cast: [String]
          type Integer, cast: [String]
        end

        assert_equal 42.2, s.validate!('42.2')
        assert_equal 42, s.validate!('42')
      end

      def test_arrays
        s = Schema.new do
          req :foo, :array, :integer, cast: [String]
        end

        assert_equal(
          { foo: [1, 2, 3] },
          s.validate!(foo: %w[1 2 3])
        )
      end

      def test_check_after_cast
        s = Schema.new do
          type Integer, cast: [String], check: proc { |v| v > 41 }
        end

        assert_equal 42, s.validate!('42')
        assert_equal 43, s.validate!('43')
        assert_equal 42, s.validate!(42)
        assert_verr { s.validate!('41') }
        assert_verr { s.validate!(42.2) }
      end

      def test_multilple_types
        e = assert_raises Exceptions::InvalidSchemaError do
          Schema.new do
            type :number, cast: [String]
          end
        end

        assert_equal 'Casting is only allowed for single-value datatypes, ' \
                     'but type Schemacop::V2::NumberValidator has classes ["Integer", "Float"].',
                     e.message
      end

      def test_custom_castings
        s = Schema.new do
          type :integer, cast: { String => proc { |v| Integer(v) } }
        end

        assert_equal 42, s.validate!('42')
      end

      def test_decimal_basis_castings
        s = Schema.new do
          type :integer, cast: [String]
        end

        assert_equal 1, s.validate!('01')
        assert_equal 8, s.validate!('08')
        assert_equal 11, s.validate!('011')
      end

      def test_string_to_nil_castings
        s = Schema.new do
          opt :int_field, :integer, cast: [String]
          opt :float_field, :float, cast: [String]
        end

        expected_int = { int_field: nil }
        expected_float = { float_field: nil }

        assert_equal expected_int, s.validate!(int_field: nil)
        assert_equal expected_int, s.validate!(int_field: '')
        assert_equal expected_int, s.validate!(int_field: '     ')

        assert_equal expected_float, s.validate!(float_field: nil)
        assert_equal expected_float, s.validate!(float_field: '')
        assert_equal expected_float, s.validate!(float_field: '     ')
      end

      def test_float_to_integer
        s = Schema.new do
          req :foo, :integer, cast: [Float]
        end

        assert_equal({ foo: 42 }, s.validate!(foo: 42.0))
        assert_equal({ foo: 42 }, s.validate!(foo: Float(42)))
      end

      def test_integer_to_float
        s = Schema.new do
          req :foo, :float, cast: [Integer]
        end

        assert_equal({ foo: 42.0 }, s.validate!(foo: 42))
        assert_equal({ foo: 42.0 }, s.validate!(foo: Integer(42)))
      end

      def test_invalid_cast_option
        s = Schema.new do
          req :foo, :integer, cast: true
        end

        assert_raises Schemacop::Exceptions::InvalidSchemaError do
          s.validate!({ foo: '42' })
        end
      end

      def test_impossible_cast
        s = Schema.new do
          req :foo, :integer, cast: [String]
        end

        assert_equal({ foo: 42 }, s.validate!(foo: '42'))
        assert_verr { s.validate!(foo: 'foo') }
      end
    end
  end
end
