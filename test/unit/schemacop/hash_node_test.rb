require 'test_helper'

module Schemacop
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
    end

    def test_property_names
      schema :hash, additional_properties: true, property_names: '^[a-zA-Z0-9]+$'
      assert_validation({})
      assert_validation(foo: :bar)
      assert_validation('foo' => 'bar')
      assert_validation('_foo39sjfdoi 345893(%' => 'bar', 'foo' => 'bar') do
        error '/', 'Property name "_foo39sjfdoi 345893(%" does not match "^[a-zA-Z0-9]+$".'
      end

      assert_json(
        type:                 :object,
        additionalProperties: true,
        propertyNames:        '^[a-zA-Z0-9]+$'
      )
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
      assert_validation(name: 'John', foo_bar: 'John', bar_baz: 42)
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

      assert_equal({ first_name: 'John', last_name: 'Doeringer', active: true, address: { street: 'Example 42' } }, @schema.validate(data).data)
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
        error '/str', 'Does not match any allOf condition.'
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
  end
end
