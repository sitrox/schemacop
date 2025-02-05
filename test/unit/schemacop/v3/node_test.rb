require 'test_helper'

module Schemacop
  module V3
    class NodeTest < V3Test
      def test_empty_schema
        # Basic, empty schema, which will allow anything
        @schema = Schemacop::Schema3.new

        assert_json({})

        assert_validation(nil)
        assert_validation([nil])
        assert_validation(1)
        assert_validation('foo')
        assert_validation(:bar)
        assert_validation({ foo: 'bar', baz: 123 })
        assert_validation([nil, 'foo', 1234, { bar: :bar }])
      end

      def test_empty_enum_schema
        @schema = Schemacop::Schema3.new enum: [1, 2, 'foo', :bar, { qux: 42 }]

        assert_json({ enum: [1, 2, 'foo', :bar, { qux: 42 }] })

        assert_validation(nil)
        assert_validation(1)
        assert_validation('foo')
        assert_validation(:bar)
        assert_validation({ qux: 42 })

        assert_validation(3) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
          end
        end
        assert_validation('bar') do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
          end
        end
        assert_validation(:foo) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
          end
        end
        assert_validation({ qux: 13 }) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
          end
        end
      end

      def test_empty_schema_with_generic_keywords
        @schema = Schemacop::Schema3.new enum:        [1, 'foo'],
                                         title:       'Empty schema',
                                         description: 'Empty schema holding generic keywords',
                                         examples:    [
                                           1,
                                           'foo'
                                         ]

        assert_json({
                      enum:        [1, 'foo'],
                      title:       'Empty schema',
                      description: 'Empty schema holding generic keywords',
                      examples:    [
                        1,
                        'foo'
                      ]
                    })
      end

      def test_swagger_example
        schema :string, examples: ['Foo', 'Foo bar']

        assert_json(
          type:     :string,
          examples: ['Foo', 'Foo bar']
        )

        assert_swagger_json(
          type:    :string,
          example: ['Foo', 'Foo bar']
        )
      end

      def test_cast_in_root
        schema :integer, cast_str: true, required: true

        assert_json(
          oneOf: [
            { type: :integer },
            { type: :string, format: :integer }
          ]
        )

        assert_validation(5)

        assert_validation(nil) do
          error '/', 'Value must be given.'
        end

        assert_validation('') do
          error '/', 'Value must be given.'
        end

        assert_validation('5')
        assert_validation('5.3') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "integer".
              - Schema 2:
                - /: String does not match format "integer".
          PLAIN
        end

        assert_cast(5, 5)
        assert_cast('5', 5)
      end

      def test_cast_in_array
        schema :array do
          list :number, cast_str: true, minimum: 3
        end

        assert_json(
          type:  :array,
          items: {
            oneOf: [
              { type: :number, minimum: 3 },
              { type: :string, format: :number }
            ]
          }
        )

        assert_validation(nil)
        assert_validation([nil])
        assert_validation([5, 5.3, '42.0', '42.42'])
        assert_validation([5, 5.3, '42.0', '42.42', 'bar']) do
          error '/[4]', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: String does not match format "number".
          PLAIN
        end
        assert_validation([2]) do
          error '/[0]', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Value must have a minimum of 3.
              - Schema 2:
                - /: Invalid type, got type "Integer", expected "string".
          PLAIN
        end
        assert_validation(['2']) do
          error '/[0]', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
              - Schema 2:
                - /: Value must have a minimum of 3.
          PLAIN
        end

        assert_cast(['3'], [3])
        assert_cast(['4', 5, '6'], [4, 5, 6])
      end

      def test_cast_in_array_required
        schema :array do
          num cast_str: true, minimum: 3, required: true
        end

        assert_json(
          type:            :array,
          items:           [
            {
              oneOf: [
                { type: :number, minimum: 3 },
                { type: :string, format: :number }
              ]
            }
          ],
          additionalItems: false
        )

        assert_validation(nil)
        assert_validation([nil]) do
          error '/[0]', 'Value must be given.'
        end
        assert_validation(['']) do
          error '/[0]', 'Value must be given.'
        end
        assert_validation([]) do
          error '/', 'Array has 0 items but must have exactly 1.'
        end
      end

      def test_not_support_block
        assert_raises_with_message Schemacop::Exceptions::InvalidSchemaError, 'Node Schemacop::V3::IntegerNode does not support blocks.' do
          schema :integer do
            int :foo
          end
        end
      end

      def test_node_no_children
        @schema = Schemacop::Schema3.new

        assert_equal(@schema.root.children, [])
      end

      def test_default_options
        Schemacop.v3_default_options = { cast_str: true }.freeze
        schema :number
        assert_cast('1', 1)
      ensure
        Schemacop.v3_default_options = {}
      end
    end
  end
end
