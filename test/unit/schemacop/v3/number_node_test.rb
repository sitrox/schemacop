require 'test_helper'

module Schemacop
  module V3
    class NumberNodeTest < V3Test
      EXP_INVALID_TYPE = 'Invalid type, expected "big_decimal" or "float" or "integer" or "rational".'.freeze

      def test_basic
        schema :number
        assert_validation 25
        assert_validation 3.323523242323523
        assert_validation(-14)
        assert_validation(-14.5)
        assert_validation(1r)
        assert_validation(2.5r)
        assert_validation(BigDecimal(6))

        assert_validation((6 + 0i)) do
          error '/', EXP_INVALID_TYPE
        end

        assert_json(type: :number)
      end

      def test_hash
        schema { num! :age }

        assert_json(
          type:                 :object,
          properties:           {
            age: { type: :number }
          },
          required:             %i[age],
          additionalProperties: false
        )
        assert_validation age: 30
        assert_validation age: 2.5r
        assert_validation age: BigDecimal(5)
      end

      def test_array
        schema(:array) { num }

        assert_json(
          type:            :array,
          items:           { type: :number },
          additionalItems: false
        )

        assert_validation [30]
        assert_validation [30.3, 42.0]
        assert_validation [30, 30r, 30.0, BigDecimal(30)]
        assert_validation ['30.3', 30.3] do
          error '/[0]', EXP_INVALID_TYPE
        end
      end

      def test_type
        schema :number

        assert_json(
          type: :number
        )

        assert_validation '42.5' do
          error '/', EXP_INVALID_TYPE
        end

        schema { num! :age }

        assert_validation age: :foo do
          error '/age', EXP_INVALID_TYPE
        end

        assert_validation age: '234' do
          error '/age', EXP_INVALID_TYPE
        end
      end

      def test_minimum
        schema :number, minimum: 0

        assert_json(
          type:    :number,
          minimum: 0
        )

        assert_validation 5
        assert_validation 0
        assert_validation(-1) do
          error '/', 'Value must have a minimum of 0.'
        end
      end

      def test_exclusive_minimum
        schema :number, exclusive_minimum: 0

        assert_json(
          type:             :number,
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
        schema :number, maximum: 5

        assert_json(
          type:    :number,
          maximum: 5
        )

        assert_validation 5
        assert_validation 0
        assert_validation(6) do
          error '/', 'Value must have a maximum of 5.'
        end
      end

      def test_exclusive_maximum
        schema :number, exclusive_maximum: 5

        assert_json(
          type:             :number,
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
        schema :number, multiple_of: 2

        assert_json(
          type:       :number,
          multipleOf: 2
        )

        assert_validation(-4.0)
        assert_validation(-2)
        assert_validation(0)
        assert_validation(2)
        assert_validation(300)

        assert_validation(5) do
          error '/', 'Value must be a multiple of 2.'
        end

        schema :number, multiple_of: 1.2

        assert_json(
          type:       :number,
          multipleOf: 1.2
        )

        assert_validation(1.2)
        assert_validation(2.4)
        assert_validation(0)
        assert_validation(-4.8)

        assert_validation(3.8) do
          error '/', 'Value must be a multiple of 1.2.'
        end
      end

      # Helper function that checks for all the options if the option is
      # an allowed class or something else, in which case it needs to raise
      def validate_self_should_error(value_to_check)
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "minimum" must be a "big_decimal" or "float" or "integer" or "rational"' do
          schema :number, minimum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "maximum" must be a "big_decimal" or "float" or "integer" or "rational"' do
          schema :number, maximum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "exclusive_minimum" must be a "big_decimal" or "float" or "integer" or "rational"' do
          schema :number, exclusive_minimum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "exclusive_maximum" must be a "big_decimal" or "float" or "integer" or "rational"' do
          schema :number, exclusive_maximum: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "multiple_of" must be a "big_decimal" or "float" or "integer" or "rational"' do
          schema :number, multiple_of: value_to_check
        end
      end

      def test_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "minimum" can\'t be greater than "maximum".' do
          schema :number, minimum: 5, maximum: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "exclusive_minimum" can\'t be '\
                                   'greater than "exclusive_maximum".' do
          schema :number, exclusive_minimum: 5, exclusive_maximum: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "multiple_of" can\'t be 0.' do
          schema :number, multiple_of: 0
        end

        validate_self_should_error(1 + 0i) # Complex
        validate_self_should_error(Object.new)
        validate_self_should_error(true)
        validate_self_should_error(false)
        validate_self_should_error('1')
        validate_self_should_error('1.0')
        validate_self_should_error('String')
      end

      def test_enum_schema
        schema :number, enum: [1, 2, 'foo', :bar, { qux: 42 }, 4.2]

        assert_json({
                      type: :number,
                      enum: [1, 2, 'foo', :bar, { qux: 42 }, 4.2]
                    })

        assert_validation(nil)
        assert_validation(1)
        assert_validation(4.2)

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not numbers
        assert_validation('foo') do
          error '/', EXP_INVALID_TYPE
        end
        assert_validation(:bar) do
          error '/', EXP_INVALID_TYPE
        end
        assert_validation({ qux: 42 }) do
          error '/', EXP_INVALID_TYPE
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation(0.5) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, 4.2].'
        end
        assert_validation(4) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, 4.2].'
        end
      end

      def test_with_generic_keywords
        schema :number, enum:        [1, 'foo', 4.2],
                        title:       'Number schema',
                        description: 'Number schema holding generic keywords',
                        examples:    [
                          1,
                          4.2
                        ]

        assert_json({
                      type:        :number,
                      enum:        [1, 'foo', 4.2],
                      title:       'Number schema',
                      description: 'Number schema holding generic keywords',
                      examples:    [
                        1,
                        4.2
                      ]
                    })
      end
    end
  end
end
