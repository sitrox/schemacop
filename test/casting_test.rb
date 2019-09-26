require 'test_helper'

module Schemacop
  class CastingTest < Minitest::Test
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
        s.validate!(foo: ['1', '2', '3'])
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

      assert_equal 'Casting is only allowed for single-value datatypes, '\
                   'but type Schemacop::NumberValidator has classes ["Integer", "Float"].',
                   e.message
    end
  end
end
