require 'test_helper'

module Schemacop
  module V3
    class HashNodeTest < V3Test
      EXP_INVALID_TYPE = 'Invalid type, expected "hash".'.freeze

      def test_basic
        schema
        assert_validation({})
        assert_json(type: :object, additionalProperties: false)

        schema :hash
        assert_validation({})

        assert_json(type: :object, additionalProperties: false)
      end

      def test_additional_properties_false
        schema
        assert_validation({})
        assert_validation(foo: :bar, bar: :baz) do
          error '/', 'Obsolete property "foo".'
          error '/', 'Obsolete property "bar".'
        end
        assert_json(type: :object, additionalProperties: false)
      end

      def test_additional_properties_true
        schema :hash, additional_properties: true
        assert_validation({})
        assert_validation(foo: :bar)
        assert_validation(foo: { bar: :baz })

        assert_json(type: :object, additionalProperties: true)
      end

      def test_additional_properties_schema
        schema :hash do
          str! :foo
          add :string
        end

        assert_validation(foo: 'bar', baz: 'foo', answer: '42')
        assert_validation(foo: 'bar', baz: 'foo', answer: 42) do
          error '/answer', 'Invalid type, expected "string".'
        end

        assert_json(
          properties:           {
            foo: { type: :string }
          },
          required:             %i[foo],
          type:                 :object,
          additionalProperties: { type: :string }
        )

        assert_nothing_raised do
          @schema.validate!({ foo: 'foo' })
        end

        assert_raises_with_message Exceptions::ValidationError, '/bar: Invalid type, expected "string".' do
          @schema.validate!({ foo: 'foo', bar: :baz })
        end
      end

      def test_property_names
        schema :hash, additional_properties: true, property_names: '^[a-zA-Z0-9]+$'
        assert_validation({})
        assert_validation(foo: :bar)
        assert_validation('foo' => 'bar')
        assert_validation(Foo: :bar)
        assert_validation('_foo39sjfdoi 345893(%' => 'bar', 'foo' => 'bar') do
          error '/', 'Property name "_foo39sjfdoi 345893(%" does not match "^[a-zA-Z0-9]+$".'
        end

        assert_json(
          type:                 :object,
          additionalProperties: true,
          propertyNames:        '^[a-zA-Z0-9]+$'
        )

        assert_cast({ foo: 123 }, { foo: 123 }.with_indifferent_access)
        assert_cast({ Foo: 123 }, { Foo: 123 }.with_indifferent_access)

        # New schema
        schema :hash, additional_properties: true, property_names: '^[a-z]+$'

        assert_validation({})
        assert_validation(foo: :bar)
        assert_validation('foo' => 'bar')
        assert_validation(Foo: :bar) do
          error '/', 'Property name "Foo" does not match "^[a-z]+$".'
        end
        assert_validation('_foo39sjfdoi 345893(%' => 'bar', 'foo' => 'bar') do
          error '/', 'Property name "_foo39sjfdoi 345893(%" does not match "^[a-z]+$".'
        end

        assert_cast({ foo: 123 }, { foo: 123 }.with_indifferent_access)
      end

      def test_required
        schema do
          str! :foo
          int? :bar
        end

        assert_validation(foo: 'sdfsd')
        assert_validation(foo: 'sdfsd', bar: 42)

        assert_validation(bar: 42) do
          error '/foo', 'Value must be given.'
        end

        assert_validation({}) do
          error '/foo', 'Value must be given.'
        end

        assert_json(
          type:                 :object,
          properties:           {
            foo: { type: :string },
            bar: { type: :integer }
          },
          required:             %i[foo],
          additionalProperties: false
        )
      end

      def test_min_properties
        schema :hash, min_properties: 2, additional_properties: true
        assert_validation(foo: :bar, bar: :baz)
        assert_validation(foo: :bar, bar: :baz, baz: :foo)

        assert_validation(foo: :bar) do
          error '/', 'Has 1 properties but needs at least 2.'
        end

        assert_validation({}) do
          error '/', 'Has 0 properties but needs at least 2.'
        end

        assert_json(
          type:                 :object,
          minProperties:        2,
          additionalProperties: true
        )
      end

      def test_max_properties
        schema :hash, max_properties: 3, additional_properties: true
        assert_validation(foo: :bar, bar: :baz)
        assert_validation(foo: :bar, bar: :baz, baz: :foo)

        assert_validation(foo: :bar, bar: :baz, baz: :foo, answer: 42) do
          error '/', 'Has 4 properties but needs at most 3.'
        end

        assert_json(
          type:                 :object,
          maxProperties:        3,
          additionalProperties: true
        )
      end

      def test_min_max_properties
        schema :hash, min_properties: 3, max_properties: 3, additional_properties: true
        assert_validation(foo: :bar, bar: :baz, baz: :foo)

        assert_validation(foo: :bar, bar: :baz, baz: :foo, answer: 42) do
          error '/', 'Has 4 properties but needs at most 3.'
        end

        assert_validation(foo: :bar, bar: :baz) do
          error '/', 'Has 2 properties but needs at least 3.'
        end

        assert_json(
          type:                 :object,
          minProperties:        3,
          maxProperties:        3,
          additionalProperties: true
        )
      end

      def test_dependencies
        schema :hash do
          str! :name
          str? :credit_card
          str? :billing_address
          str? :phone_number

          dep :credit_card, :billing_address, :phone_number
          dep :billing_address, :credit_card
        end

        assert_validation(name: 'John')
        assert_validation(name: 'John', credit_card: '23423523', billing_address: 'Example 3', phone_number: '234')

        assert_validation(name: 'John', credit_card: '23423523') do
          error '/', 'Missing property "billing_address" because "credit_card" is given.'
          error '/', 'Missing property "phone_number" because "credit_card" is given.'
        end

        assert_validation(name: 'John', billing_address: 'Example 3') do
          error '/', 'Missing property "credit_card" because "billing_address" is given.'
        end

        assert_json(
          type:                 :object,
          properties:           {
            name:            { type: :string },
            credit_card:     { type: :string },
            billing_address: { type: :string },
            phone_number:    { type: :string }
          },
          required:             %i[name],
          dependencies:         {
            credit_card:     %i[billing_address phone_number],
            billing_address: %i[credit_card]
          },
          additionalProperties: false
        )
      end

      def test_pattern_properties_wo_additional
        schema additional_properties: false do
          str! :name
          str?(/^foo_.*$/)
          int?(/^bar_.*$/)
        end

        assert_validation(name: 'John', foo_bar: 'John')
        assert_validation(name: 'John', foo_bar: 'John', bar_baz: 42, foo_baz: '42')
        assert_validation(name: 'John', foo_baz: 'John', bar_baz: 42)

        assert_validation(name: 'John', xy: 'John', bar_baz: 'Doe') do
          error '/', 'Obsolete property "xy".'
          error '/bar_baz', 'Invalid type, expected "integer".'
        end

        assert_json(
          type:                 :object,
          properties:           {
            name: { type: :string }
          },
          patternProperties:    {
            '^foo_.*$': { type: :string },
            '^bar_.*$': { type: :integer }
          },
          additionalProperties: false,
          required:             %i[name]
        )
      end

      def test_pattern_properties_w_additional
        schema additional_properties: true do
          int? :builtin
          str?(/^S_/)
          int?(/^I_/)
          add :string
        end

        assert_validation(builtin: 42)
        assert_validation(keyword: 'value')

        assert_validation(keyword: 42) do
          error '/keyword', 'Invalid type, expected "string".'
        end

        assert_json(
          type:                 'object',
          properties:           {
            builtin: { type: :integer }
          },
          patternProperties:    {
            '^S_': { type: :string },
            '^I_': { type: :integer }
          },
          additionalProperties: { type: :string }
        )
      end

      def test_pattern_properties_casting
        schema do
          int?(/^id_.*$/)
          int?(/^val.*$/)
        end

        assert_json({
                      type:                 :object,
                      patternProperties:    {
                        '^id_.*$': { type: :integer },
                        '^val.*$': { type: :integer }
                      },
                      additionalProperties: false
                    })

        assert_validation({})
        assert_validation({ id_foo: 1 })
        assert_validation({ id_foo: 1, id_bar: 2 })
        assert_validation({ id_foo: 1, id_bar: 2, value: 4 })

        assert_cast({ id_foo: 1 }, { id_foo: 1 }.with_indifferent_access)
        assert_cast({ id_foo: 1, id_bar: 2 }, { id_foo: 1, id_bar: 2 }.with_indifferent_access)
        assert_cast({ id_foo: 1, id_bar: 2, value: 4 }, { id_foo: 1, id_bar: 2, value: 4 }.with_indifferent_access)
      end

      def test_defaults
        schema do
          str? :first_name, default: 'John'
          str? :last_name, default: 'Doe'
          str! :active, format: :boolean
          hsh? :address, default: {} do
            str? :street, default: 'Example 42'
          end
        end

        data = { last_name: 'Doeringer', active: 'true' }
        data_was = data.dup

        expected_data = { first_name: 'John', last_name: 'Doeringer', active: true, address: { street: 'Example 42' } }.with_indifferent_access

        assert_equal(expected_data, @schema.validate(data).data)
        assert_equal data_was, data

        schema do
          hsh? :address do
            str? :street, default: 'Example 42'
          end
        end

        assert_equal({}, @schema.validate({}).data)
      end

      def test_all_of
        schema do
          all_of! :str do
            str min_length: 3
            str max_length: 5
          end
        end

        assert_validation(str: '123')
        assert_validation(str: '1234')
        assert_validation(str: '12345')
        assert_validation(str: '0') do
          error '/str', 'Does not match all allOf conditions.'
        end
      end

      def test_one_of_required
        schema do
          one_of! :str do
            str min_length: 4
            str min_length: 0, max_length: 4
          end
        end

        assert_validation(str: '12345')
        assert_validation(str: '123')
        assert_validation(str: nil) do
          error '/str', 'Value must be given.'
        end
        assert_validation(str: '1234') do
          error '/str', 'Matches 2 definitions but should match exactly 1.'
        end
      end

      def test_one_of_optional
        schema do
          one_of? :str do
            str min_length: 4
            str min_length: 0, max_length: 4
          end
        end

        assert_validation(str: '12345')
        assert_validation(str: '123')
        assert_validation(str: nil)
        assert_validation({})
        assert_validation(str: '1234') do
          error '/str', 'Matches 2 definitions but should match exactly 1.'
        end
      end

      def test_any_of_required
        schema do
          any_of! :str_or_int do
            str
            int
          end
        end

        assert_validation(str_or_int: 'Hello World')
        assert_validation(str_or_int: 42)
        assert_validation(str_or_int: :foo) do
          error '/str_or_int', 'Does not match any anyOf condition.'
        end
      end

      def test_any_of_optional
        schema do
          any_of? :str_or_int do
            str
            int
          end
        end

        assert_validation(str_or_int: 'Hello World')
        assert_validation(str_or_int: 42)
        assert_validation(str_or_int: nil)
        assert_validation({})
        assert_validation(str_or_int: :foo) do
          error '/str_or_int', 'Does not match any anyOf condition.'
        end
      end

      def test_is_not_required
        schema do
          is_not! :foo, required: true do
            str
          end
        end

        assert_validation(foo: 42)
        assert_validation(foo: true)
        assert_validation(foo: { bar: :baz })
        assert_validation(foo: nil) do
          error '/foo', 'Value must be given.'
        end
        assert_validation(foo: 'string') do
          error '/foo', 'Must not match schema: {"type"=>"string"}.'
        end
      end

      def test_is_not_optional
        schema do
          is_not? :foo do
            str
          end
        end

        assert_validation(foo: 42)
        assert_validation(foo: true)
        assert_validation(foo: { bar: :baz })
        assert_validation(foo: nil)
        assert_validation(foo: 'string') do
          error '/foo', 'Must not match schema: {"type"=>"string"}.'
        end
      end

      # Helper function that checks for all the options if the option is
      # an integer or something else, in which case it needs to raise
      def validate_self_should_error(value_to_check)
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "min_properties" must be an "integer"' do
          schema :hash, min_properties: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "max_properties" must be an "integer"' do
          schema :hash, max_properties: value_to_check
        end
      end

      def test_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Pattern properties can\'t be required.' do
          schema :hash do
            str!(/[a-z]+/)
          end
        end

        validate_self_should_error(1.0)
        validate_self_should_error(4r)
        validate_self_should_error(true)
        validate_self_should_error(false)
        validate_self_should_error((4 + 6i))
        validate_self_should_error('13')
        validate_self_should_error('Lorem ipsum')

        # rubocop:disable Lint/BooleanSymbol
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "additional_properties" must be a boolean value' do
          schema :hash, additional_properties: :true
        end
        # rubocop:enable Lint/BooleanSymbol
      end

      def test_doc_example
        schema :hash do
          scm :address do
            str! :street
            int! :number
            str! :zip
          end
          int? :id
          str! :name
          ref! :address, :address
          ary! :additional_addresses, default: [] do
            ref :address
          end
          ary? :comments, :array, default: [] do
            str
          end
          hsh! :jobs, min_properties: 1 do
            str?(/^[0-9]+$/)
          end
        end

        assert_validation(
          id:                   42,
          name:                 'John Doe',
          address:              {
            street: 'Silver Street',
            number: 4,
            zip:    '38234C'
          },
          additional_addresses: [
            { street: 'Example street', number: 42, zip: '8048' }
          ],
          comments:             [
            'This is a comment'
          ],
          jobs:                 {
            2020 => 'Software Engineer'
          }
        )
      end

      def test_cast_without_additional
        schema :hash do
          str! :foo, format: :integer
        end

        assert_validation(nil)
        assert_validation(foo: '1')
        assert_cast({ foo: '1' }, { foo: 1 }.with_indifferent_access)

        assert_validation(foo: '1', bar: '2') do
          error '/', 'Obsolete property "bar".'
        end

        assert_json(
          type:                 'object',
          properties:           {
            foo: {
              type:   :string,
              format: :integer
            }
          },
          additionalProperties: false,
          required:             %i[foo]
        )
      end

      def test_cast_with_additional
        schema :hash, additional_properties: true do
          str! :foo, format: :integer
        end

        assert_validation(nil)
        assert_validation(foo: '1')
        assert_cast({ foo: '1' }, { foo: 1 }.with_indifferent_access)

        assert_validation(foo: '1', bar: nil)
        assert_validation(foo: '1', bar: '2')
        assert_cast({ foo: '1', bar: '2' }, { foo: 1, bar: '2' }.with_indifferent_access)

        assert_json(
          type:                 'object',
          properties:           {
            foo: {
              type:   :string,
              format: :integer
            }
          },
          additionalProperties: true,
          required:             %i[foo]
        )
      end

      def test_multiple_add_in_schema
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'You can only use "add" once to specify additional properties.' do
          schema :hash do
            add :integer
            add :string
          end
        end
      end

      def test_cast_with_additional_in_block
        schema :hash do
          str! :foo, format: :integer
          add :string
        end

        assert_validation(nil)
        assert_validation(foo: '1')
        assert_cast({ foo: '1' }, { foo: 1 }.with_indifferent_access)

        assert_validation(foo: '1', bar: nil)
        assert_validation(foo: '1', bar: '2')
        assert_cast({ foo: '1', bar: '2' }, { foo: 1, bar: '2' }.with_indifferent_access)

        assert_json(
          type:                 'object',
          properties:           {
            foo: {
              type:   :string,
              format: :integer
            }
          },
          additionalProperties: { type: :string },
          required:             %i[foo]
        )
      end

      def test_cast_with_additional_in_block_with_casting
        schema :hash do
          str! :foo, format: :integer
          add :string, format: :integer
        end

        assert_validation(nil)
        assert_validation(foo: '1')
        assert_cast({ foo: '1' }, { foo: 1 }.with_indifferent_access)

        assert_validation(foo: '1', bar: nil)
        assert_validation(foo: '1', bar: '2')
        assert_cast({ foo: '1', bar: '2' }, { foo: 1, bar: 2 }.with_indifferent_access)
      end

      def test_cast_with_additional_any_of
        schema :hash do
          str! :foo, format: :integer
          add :any_of do
            str
            int
          end
        end

        assert_validation(nil)
        assert_validation(foo: '1')
        assert_cast({ foo: '1' }, { foo: 1 }.with_indifferent_access)

        assert_validation(foo: '1', bar: nil)
        assert_validation(foo: '1', bar: '2')
        assert_validation(foo: '1', bar: '2', baz: 3)
        assert_validation(foo: '1', bar: '2', baz: 3, qux: [1, 2]) do
          error '/qux', 'Does not match any anyOf condition.'
        end

        assert_cast({ foo: '1', bar: '2' }, { foo: 1, bar: '2' }.with_indifferent_access)

        assert_json(
          type:                 'object',
          properties:           {
            foo: {
              type:   :string,
              format: :integer
            }
          },
          additionalProperties: {
            anyOf: [
              { type: :string },
              { type: :integer }
            ]
          },
          required:             %i[foo]
        )
      end

      def test_cast_with_additional_any_of_with_casting
        schema :hash do
          str! :foo, format: :integer
          add :any_of do
            str format: :integer
            str format: :date
            int
          end
        end

        assert_validation(nil)
        assert_validation(foo: '1')
        assert_cast({ foo: '1' }, { foo: 1 }.with_indifferent_access)

        assert_validation(foo: '1', bar: nil)
        assert_validation(foo: '1', bar: '2')
        assert_validation(foo: '1', bar: '2', baz: 3)
        assert_validation(foo: '1', bar: '2', baz: 3, qux: [1, 2]) do
          error '/qux', 'Does not match any anyOf condition.'
        end

        assert_cast({ foo: '1', bar: '2' }, { foo: 1, bar: 2 }.with_indifferent_access)
        assert_cast({ foo: '1', bar: '2', qux: '2020-01-13', asd: 1 }, { foo: 1, bar: 2, qux: Date.new(2020, 1, 13), asd: 1 }.with_indifferent_access)

        assert_json(
          type:                 'object',
          properties:           {
            foo: {
              type:   :string,
              format: :integer
            }
          },
          additionalProperties: {
            anyOf: [
              {
                type:   :string,
                format: :integer
              },
              {
                type:   :string,
                format: :date
              },
              {
                type: :integer
              }
            ]
          },
          required:             %i[foo]
        )
      end

      def test_enum_schema
        schema :hash do
          str! :foo, enum: ['bar', 'qux', 123, :faz]
        end

        assert_json({
                      type:                 :object,
                      additionalProperties: false,
                      properties:           {
                        foo: {
                          type: :string,
                          enum: ['bar', 'qux', 123, :faz]
                        }
                      },
                      required:             [:foo]
                    })

        assert_validation(nil)
        assert_validation({ foo: 'bar' })
        assert_validation({ foo: 'qux' })

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not strings
        assert_validation({ foo: 123 }) do
          error '/foo', 'Invalid type, expected "string".'
        end
        assert_validation({ foo: :faz }) do
          error '/foo', 'Invalid type, expected "string".'
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation({ foo: 'Lorem ipsum' }) do
          error '/foo', 'Value not included in enum ["bar", "qux", 123, :faz].'
        end
      end

      def test_with_generic_keywords
        schema :hash, title: 'Hash', description: 'A hash with a description' do
          str! :foo,
               enum:        ['bar', 'qux', 123, :faz],
               title:       'A string',
               description: 'A string in the hash',
               examples:    [
                 'foo'
               ]
        end

        assert_json({
                      type:                 :object,
                      additionalProperties: false,
                      title:                'Hash',
                      description:          'A hash with a description',
                      properties:           {
                        foo: {
                          type:        :string,
                          enum:        ['bar', 'qux', 123, :faz],
                          title:       'A string',
                          examples:    ['foo'],
                          description: 'A string in the hash'
                        }
                      },
                      required:             [:foo]
                    })
      end

      def test_hash_with_indifferent_access
        schema :hash do
          str! :foo
          int? :bar
          add :symbol
        end

        # Test with symbol notation
        hash = ActiveSupport::HashWithIndifferentAccess.new

        assert_validation(hash) do
          error '/foo', 'Value must be given.'
        end
        hash[:foo] = 'Foo'
        assert_validation(hash)
        hash[:bar] = 123
        assert_validation(hash)
        hash[:qux] = :ruby
        assert_validation(hash)

        # Test with string notation
        hash = ActiveSupport::HashWithIndifferentAccess.new

        assert_validation(hash) do
          error '/foo', 'Value must be given.'
        end
        hash['foo'] = 'Foo'
        assert_validation(hash)
        hash['bar'] = 123
        assert_validation(hash)
        hash['qux'] = :ruby
        assert_validation(hash)
      end

      def test_invalid_schema
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Child nodes must have a name.' do
          schema :hash do
            int!
          end
        end
      end

      def test_schema_with_string_keys
        schema :hash do
          int! 'foo'
        end

        assert_validation(nil)
        assert_validation({ 'foo' => 42 })
        assert_validation({ foo: 42 })

        assert_cast({ 'foo' => 42 }, { 'foo' => 42 })
        assert_cast({ foo: 42 }, { foo: 42 }.with_indifferent_access)

        assert_validation({}) do
          error '/foo', 'Value must be given.'
        end

        assert_validation({ :foo => 42, 'foo' => 43 }) do
          error '/', 'Has 1 ambiguous properties: [:foo].'
        end
      end

      def test_schema_with_string_keys_in_data
        schema :hash do
          int! :foo
        end

        assert_validation(nil)
        assert_validation({ 'foo' => 42 })
        assert_validation({ foo: 42 })

        assert_cast({ 'foo' => 42 }, { 'foo' => 42 })
        assert_cast({ foo: 42 }, { foo: 42 }.with_indifferent_access)

        assert_validation({}) do
          error '/foo', 'Value must be given.'
        end

        assert_validation({ :foo => 42, 'foo' => 43 }) do
          error '/', 'Has 1 ambiguous properties: [:foo].'
        end
      end

      def test_invalid_options
        assert_raises_with_message Schemacop::Exceptions::InvalidSchemaError, 'Options [:foo] are not allowed for this node.' do
          schema :hash, foo: 'bar' do
            int! :id
          end
        end
      end

      # def test_invalid_key_names
      #   schema :hash do
      #     int!
      #   end
      # end
    end
  end
end
