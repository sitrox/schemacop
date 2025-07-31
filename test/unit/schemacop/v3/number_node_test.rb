require 'test_helper'

module Schemacop
  module V3
    class NumberNodeTest < V3Test
      def self.invalid_type_error(type)
        "Invalid type, got type \"#{type}\", expected \"big_decimal\" or \"float\" or \"integer\" or \"rational\"."
      end

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
          error '/', NumberNodeTest.invalid_type_error(Complex)
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
        schema(:array) do
          list :number
        end

        assert_json(
          type:  :array,
          items: { type: :number }
        )

        assert_validation [30]
        assert_validation [30.3, 42.0]
        assert_validation [30, 30r, 30.0, BigDecimal(30)]
        assert_validation ['30.3', 30.3] do
          error '/[0]', NumberNodeTest.invalid_type_error(String)
        end
      end

      def test_type
        schema :number

        assert_json(
          type: :number
        )

        assert_validation '42.5' do
          error '/', NumberNodeTest.invalid_type_error(String)
        end

        schema { num! :age }

        assert_validation age: :foo do
          error '/age', NumberNodeTest.invalid_type_error(Symbol)
        end

        assert_validation age: '234' do
          error '/age', NumberNodeTest.invalid_type_error(String)
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

        assert_swagger_json(
          type:             :number,
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

        assert_swagger_json(
          type:             :number,
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

      def test_max_precision
        schema :number, max_precision: 2

        assert_json(
          type:         :number,
          maxPrecision: 2
        )

        # Valid cases
        assert_validation(42)          # Integer
        assert_validation(3.14)        # 2 decimal places
        assert_validation(3.1)         # 1 decimal place
        assert_validation(3.0)         # 0 decimal places
        assert_validation(0.12)        # 2 decimal places
        assert_validation(1r)          # Rational should not be affected

        # BigDecimal valid cases
        assert_validation(BigDecimal('3.14'))     # 2 decimal places
        assert_validation(BigDecimal('3.1'))      # 1 decimal place
        assert_validation(BigDecimal('3.0'))      # 0 decimal places (with trailing zero)
        assert_validation(BigDecimal('3'))        # 0 decimal places
        assert_validation(BigDecimal('3.00'))     # trailing zeros should be ignored

        # Invalid cases - Float
        assert_validation(3.141) do
          error '/', 'Value must have a maximum precision of 2 digits after the decimal point.'
        end

        assert_validation(0.123) do
          error '/', 'Value must have a maximum precision of 2 digits after the decimal point.'
        end

        assert_validation(123.456789) do
          error '/', 'Value must have a maximum precision of 2 digits after the decimal point.'
        end

        # Invalid cases - BigDecimal
        assert_validation(BigDecimal('3.141')) do
          error '/', 'Value must have a maximum precision of 2 digits after the decimal point.'
        end

        assert_validation(BigDecimal('0.123')) do
          error '/', 'Value must have a maximum precision of 2 digits after the decimal point.'
        end

        # Test with max_precision: 0
        schema :number, max_precision: 0

        assert_json(
          type:         :number,
          maxPrecision: 0
        )

        assert_validation(42)
        assert_validation(3.0)
        assert_validation(0)
        assert_validation(BigDecimal('3'))
        assert_validation(BigDecimal('3.0'))
        assert_validation(BigDecimal('3.00'))

        assert_validation(3.1) do
          error '/', 'Value must have a maximum precision of 0 digits after the decimal point.'
        end

        assert_validation(BigDecimal('3.1')) do
          error '/', 'Value must have a maximum precision of 0 digits after the decimal point.'
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

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "max_precision" must be a non-negative integer.' do
          schema :number, max_precision: -1
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "max_precision" must be a non-negative integer.' do
          schema :number, max_precision: 2.5
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "max_precision" must be a non-negative integer.' do
          schema :number, max_precision: '2'
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
          error '/', NumberNodeTest.invalid_type_error(String)
        end
        assert_validation(:bar) do
          error '/', NumberNodeTest.invalid_type_error(Symbol)
        end
        assert_validation({ qux: 42 }) do
          error '/', NumberNodeTest.invalid_type_error(Hash)
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation(0.5) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}, 4.2].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, 4.2].'
          end
        end
        assert_validation(4) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}, 4.2].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, 4.2].'
          end
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

      def test_combined_validations_with_max_precision
        schema :number, minimum: 0, maximum: 100, max_precision: 1

        assert_json(
          type:         :number,
          minimum:      0,
          maximum:      100,
          maxPrecision: 1
        )

        assert_validation(50.5)
        assert_validation(0.1)
        assert_validation(100.0)

        assert_validation(50.55) do
          error '/', 'Value must have a maximum precision of 1 digits after the decimal point.'
        end

        assert_validation(-0.1) do
          error '/', 'Value must have a minimum of 0.'
        end

        assert_validation(100.1) do
          error '/', 'Value must have a maximum of 100.'
        end
      end

      def test_cast_str
        schema :number, cast_str: true, minimum: 0.0, maximum: 50r, multiple_of: BigDecimal('0.5')

        assert_cast('1', 1, check_type: true)
        assert_cast(1, 1, check_type: true)

        assert_cast('08', 8, check_type: true)
        assert_cast('09', 9, check_type: true)
        assert_cast('050', 50, check_type: true)
        assert_cast('01', 1, check_type: true)

        assert_validation(nil)
        assert_validation('')

        assert_cast('1.0', 1.0, check_type: true)
        assert_cast(1.0, 1.0, check_type: true)

        assert_validation('42')
        assert_validation('0.5')

        assert_validation('true') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: String does not match format "number".
          PLAIN
        end

        assert_validation('51') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: Value must have a maximum of 50/1.
          PLAIN
        end

        assert_validation('-2') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: Value must have a minimum of 0.0.
          PLAIN
        end

        assert_validation('3.1415') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: Value must be a multiple of 0.5.
          PLAIN
        end
      end
    end
  end
end
