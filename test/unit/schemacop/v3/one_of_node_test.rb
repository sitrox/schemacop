require 'test_helper'

module Schemacop
  module V3
    class OneOfNodeTest < V3Test
      def test_todo
        schema(:one_of) do
          hsh do
            str! :name
            str! :email
          end
          hsh do
            int! :id
          end
        end

        assert_validation(name: 'John', email: 'john@doe.com')
        assert_validation(id: 42)
        assert_validation(id: 42, name: 'John') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /email: Value must be given.
                - /: Obsolete property "id".
              - Schema 2:
                - /: Obsolete property "name".
          PLAIN
        end
      end

      def test_optional
        schema :one_of do
          num multiple_of: 2
          num multiple_of: 3
          str
        end

        assert_validation(nil)
        assert_validation(4)
        assert_validation(9)
        assert_validation('foo')
        assert_validation(12) do
          error '/', <<~PLAIN.strip
            Matches 2 schemas but should match exactly 1:
              - Schema 1: Matches
              - Schema 2: Matches
              - Schema 3:
                - /: Invalid type, got type "Integer", expected "string".
          PLAIN
        end
        assert_validation(1) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Value must be a multiple of 2.
              - Schema 2:
                - /: Value must be a multiple of 3.
              - Schema 3:
                - /: Invalid type, got type "Integer", expected "string".
          PLAIN
        end
        assert_validation(:foo) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "Symbol", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: Invalid type, got type "Symbol", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 3:
                - /: Invalid type, got type "Symbol", expected "string".
          PLAIN
        end
      end

      def test_required
        schema :one_of, required: true do
          num multiple_of: 2
          num multiple_of: 3
          str
        end

        assert_validation(8)
        assert_validation(9)

        assert_validation(nil) do
          error '/', 'Value must be given.'
        end
      end

      def test_nested
        schema :one_of do
          hsh do
            one_of! :foo do
              num multiple_of: 2
              num multiple_of: 3
            end
          end
          hsh do
            num? :foo, multiple_of: 7
          end
        end

        assert_validation(foo: 2)
        assert_validation(foo: 9)
        assert_validation(foo: 7)
        assert_validation(foo: 14) do
          error '/', <<~PLAIN.strip
            Matches 2 schemas but should match exactly 1:
              - Schema 1: Matches
              - Schema 2: Matches
          PLAIN
        end
        assert_validation(foo: 12) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /foo: Matches 2 schemas but should match exactly 1:
                  - Schema 1: Matches
                  - Schema 2: Matches
              - Schema 2:
                - /foo: Value must be a multiple of 7.
          PLAIN
        end

        assert_json(
          oneOf: [
            {
              type:                 :object,
              properties:           {
                foo: {
                  oneOf: [
                    { type: :number, multipleOf: 2 },
                    { type: :number, multipleOf: 3 }
                  ]
                }
              },
              required:             %i[foo],
              additionalProperties: false
            },
            {
              type:                 :object,
              properties:           {
                foo: { type: :number, multipleOf: 7 }
              },
              additionalProperties: false
            }
          ]
        )
      end

      def test_casting
        schema do
          one_of! :created_at do
            str format: :date
            str format: :date_time
          end
        end

        assert_validation(created_at: '2020-01-01')
        assert_validation(created_at: '2020-01-01T17:38:20')

        assert_cast(
          { created_at: '2020-01-01' },
          { created_at: Date.new(2020, 1, 1) }.with_indifferent_access
        )
        assert_cast(
          { created_at: '2020-01-01T17:38:20' },
          { created_at: DateTime.new(2020, 1, 1, 17, 38, 20) }.with_indifferent_access
        )
      end

      def test_defaults
        schema do
          one_of! :foo do
            hsh { str? :bar }
            hsh { str? :baz, default: 'Baz' }
          end
        end

        assert_validation(foo: { bar: 'Bar' })
        assert_validation(foo: { baz: 'Baz' })

        assert_validation(foo: { xyz: 'Baz' }) do
          error '/foo', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Obsolete property "xyz".
              - Schema 2:
                - /: Obsolete property "xyz".
          PLAIN
        end

        assert_cast(
          { foo: { bar: nil } },
          { foo: { bar: nil } }.with_indifferent_access
        )

        assert_cast(
          { foo: { baz: nil } },
          { foo: { baz: 'Baz' } }.with_indifferent_access
        )

        schema do
          one_of! :foo do
            hsh { str? :bar, format: :date }
            hsh { str? :bar, default: 'Baz', format: :date_time }
          end
        end

        assert_cast(
          { foo: { bar: '1990-01-13' } },
          { foo: { bar: Date.new(1990, 1, 13) } }.with_indifferent_access
        )

        assert_cast(
          { foo: { bar: '1990-01-13T10:00:00Z' } },
          { foo: { bar: DateTime.new(1990, 1, 13, 10, 0, 0) } }.with_indifferent_access
        )
      end

      def test_with_generic_keywords
        schema :one_of, title:       'oneOf schema',
                        description: 'oneOf schema holding generic keywords',
                        examples:    [
                          'foo'
                        ] do
                          str
                          int
                        end

        assert_json({
                      oneOf:       [
                        { type: :string },
                        { type: :integer }
                      ],
                      title:       'oneOf schema',
                      description: 'oneOf schema holding generic keywords',
                      examples:    [
                        'foo'
                      ]
                    })
      end

      def test_invalid_schema
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Node "one_of" makes only sense with at least 2 items.' do
          schema :one_of
        end
      end

      def test_treat_blank_as_nil
        schema :one_of, treat_blank_as_nil: true do
          boo
          str format: :boolean
        end

        assert_validation(nil)
        assert_validation('')
        assert_validation('true')
        assert_validation(true)
      end

      def test_treat_blank_as_nil_with_invalid_encoding
        schema :one_of, treat_blank_as_nil: true do
          str
          int
        end

        # A string with an invalid byte sequence is not blank, so it is matched
        # against the items rather than treated as nil.
        assert_validation invalid_string do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: String has invalid "UTF-8" encoding.
              - Schema 2:
                - /: Invalid type, got type "String", expected "integer".
          PLAIN
        end
      end

      def test_treat_blank_as_nil_with_incompatible_encoding
        schema :one_of, treat_blank_as_nil: true do
          boo
          str format: :boolean
        end

        assert_validation ''.encode('UTF-16')

        assert_validation 'true'.encode('UTF-16') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "boolean".
              - Schema 2:
                - /: String does not match format "boolean".
          PLAIN
        end
      end

      # With cast_str as default option, int gets wrapped in a OneOfNode containing
      # [IntegerNode, StringNode(format: :integer)]. When combined with a sibling str
      # node in one_of, numeric-looking strings like "1" match both the wrapped int
      # (via StringNode(format: :integer)) and the plain str, causing a "matches 2"
      # validation error.
      def test_default_cast_str_with_int_and_str
        Schemacop.v3_default_options = { cast_str: true }.freeze

        schema :one_of do
          int
          str
        end

        assert_validation(42)
        assert_validation('hello')
        assert_validation('1')
        assert_cast(42, 42)
        assert_cast('hello', 'hello')
        assert_cast('1', '1')
      ensure
        Schemacop.v3_default_options = {}
      end
    end
  end
end
