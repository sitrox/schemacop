require 'test_helper'

module Schemacop
  module V3
    class IntegerNodeTest < V3Test
      EXP_INVALID_TYPE = 'Invalid type, expected "integer".'.freeze

      def test_basic
        schema :integer

        assert_json(type: :integer)

        assert_validation 25
        assert_validation(-14)
      end

      def test_hash
        schema { int! :age }

        assert_json(
          type:                 :object,
          properties:           {
            age: { type: :integer }
          },
          required:             %i[age],
          additionalProperties: false
        )

        assert_validation age: 30
      end

      def test_array
        schema(:array) { int }

        assert_json(
          type:            :array,
          items:           [type: :integer],
          additionalItems: false
        )

        assert_validation [30]
        assert_validation [30, 42]
        assert_validation [30, '30'] do
          error '/[1]', EXP_INVALID_TYPE
        end
      end

      def test_type
        schema :integer

        assert_json(
          type: :integer
        )

        assert_validation 42.5 do
          error '/', EXP_INVALID_TYPE
        end

        assert_validation '42.5' do
          error '/', EXP_INVALID_TYPE
        end

        schema { int! :age }

        assert_json(
          type:                 :object,
          properties:           {
            age: { type: :integer }
          },
          required:             %i[age],
          additionalProperties: false
        )

        assert_validation age: :foo do
          error '/age', EXP_INVALID_TYPE
        end

        assert_validation age: '234' do
          error '/age', EXP_INVALID_TYPE
        end
      end

      def test_minimum
        schema :integer, minimum: 0

        assert_json(
          type:    :integer,
          minimum: 0
        )

        assert_validation 5
        assert_validation 0
        assert_validation(-1) do
          error '/', 'Value must have a minimum of 0.'
        end
      end

      def test_exclusive_minimum
        schema :integer, exclusive_minimum: 0

        assert_json(
          type:             :integer,
          exclusiveMinimum: 0
        )

        assert_validation 5
        assert_validation 1
        assert_validation(0) do
          error '/', 'Value must have an exclusive minimum of 0.'
        end
        assert_validation(-5) do
          error '/', 'Value must have an exclusive minimum of 0.'
        end
      end

      def test_maximum
        schema :integer, maximum: 5

        assert_json(
          type:    :integer,
          maximum: 5
        )

        assert_validation 5
        assert_validation 0
        assert_validation(6) do
          error '/', 'Value must have a maximum of 5.'
        end
      end

      def test_exclusive_maximum
        schema :integer, exclusive_maximum: 5

        assert_json(
          type:             :integer,
          exclusiveMaximum: 5
        )

        assert_validation 4
        assert_validation 1
        assert_validation(5) do
          error '/', 'Value must have an exclusive maximum of 5.'
        end
        assert_validation(9) do
          error '/', 'Value must have an exclusive maximum of 5.'
        end
      end

      def test_multiple_of
        schema :integer, multiple_of: 2

        assert_json(
          type:       :integer,
          multipleOf: 2
        )

        assert_validation(-4)
        assert_validation(-2)
        assert_validation(0)
        assert_validation(2)
        assert_validation(300)

        assert_validation(5) do
          error '/', 'Value must be a multiple of 2.'
        end
      end

      def test_default
        schema :integer, default: 5

        assert_json(
          type:    :integer,
          default: 5
        )

        assert_validation(nil)
        assert_validation(50)
        assert_validation(5.2) do
          error '/', 'Invalid type, expected "integer".'
        end

        assert_cast(5, 5)
        assert_cast(6, 6)
        assert_cast(nil, 5)
      end
    end
  end
end
