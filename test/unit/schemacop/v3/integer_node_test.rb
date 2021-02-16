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
          items:           [
            {
              type: :integer
            }
          ],
          additionalItems: false
        )

        assert_validation [30]
        assert_validation [30, 42] do
          error '/', 'Array has 2 items but must have exactly 1.'
        end
        assert_validation [30, '30'] do
          error '/', 'Array has 2 items but must have exactly 1.'
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

        assert_validation age: 10.0 do
          error '/age', EXP_INVALID_TYPE
        end

        assert_validation age: 4r do
          error '/age', EXP_INVALID_TYPE
        end

        assert_validation age: (4 + 0i) do
          error '/age', EXP_INVALID_TYPE
        end

        assert_validation age: BigDecimal(5) do
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

        assert_swagger_json(
          type:             :integer,
          minimum:          0,
          exclusiveMinimum: true
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

        assert_swagger_json(
          type:             :integer,
          maximum:          5,
          exclusiveMaximum: true
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

      # Helper function that checks for all the options if the option is
      # an integer or something else, in which case it needs to raise
      def validate_self_should_error(value_to_check)
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "minimum" must be a "integer"' do
          schema :integer, minimum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "maximum" must be a "integer"' do
          schema :integer, maximum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "exclusive_minimum" must be a "integer"' do
          schema :integer, exclusive_minimum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "exclusive_maximum" must be a "integer"' do
          schema :integer, exclusive_maximum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "multiple_of" must be a "integer"' do
          schema :integer, multiple_of: value_to_check
        end
      end

      def test_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "minimum" can\'t be greater than "maximum".' do
          schema :integer, minimum: 5, maximum: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "exclusive_minimum" can\'t be '\
                                   'greater than "exclusive_maximum".' do
          schema :integer, exclusive_minimum: 5, exclusive_maximum: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "multiple_of" can\'t be 0.' do
          schema :integer, multiple_of: 0
        end

        validate_self_should_error(1.0) # Float
        validate_self_should_error(1r)  # Rational
        validate_self_should_error(1 + 0i) # Complex
        validate_self_should_error(BigDecimal(5)) # BigDecimal
        validate_self_should_error(Object.new)
        validate_self_should_error(true)
        validate_self_should_error(false)
        validate_self_should_error('1')
        validate_self_should_error('String')
      end

      def test_enum_schema
        schema :integer, enum: [1, 2, 'foo', :bar, { qux: 42 }]

        assert_json({
                      type: :integer,
                      enum: [1, 2, 'foo', :bar, { qux: 42 }]
                    })

        assert_validation(nil)
        assert_validation(1)

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not integers
        assert_validation('foo') do
          error '/', 'Invalid type, expected "integer".'
        end
        assert_validation(:bar) do
          error '/', 'Invalid type, expected "integer".'
        end
        assert_validation({ qux: 42 }) do
          error '/', 'Invalid type, expected "integer".'
        end

        # This needs to fail as it is a number (float) and not an integer
        assert_validation(4.2) do
          error '/', 'Invalid type, expected "integer".'
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation(13) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
        end
        assert_validation(4) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
        end
      end

      def test_with_generic_keywords
        schema :integer, enum:        [1, 'foo'],
                         title:       'Integer schema',
                         description: 'Integer schema holding generic keywords',
                         examples:    [
                           1
                         ]

        assert_json({
                      type:        :integer,
                      enum:        [1, 'foo'],
                      title:       'Integer schema',
                      description: 'Integer schema holding generic keywords',
                      examples:    [
                        1
                      ]
                    })
      end
    end
  end
end
