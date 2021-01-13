require 'test_helper'

module Schemacop
  module V3
    class ArrayNodeTest < V3Test
      EXP_INVALID_TYPE = 'Invalid type, expected "array".'.freeze

      def test_basic
        schema :array
        assert_json(type: :array)
        assert_validation []
        assert_validation [nil, nil]
        assert_validation [2234, 'foo', :bar]
      end

      def test_in_object
        schema { ary! :items }
        assert_json(
          type:                 :object,
          properties:           {
            items: { type: :array }
          },
          required:             %i[items],
          additionalProperties: false
        )

        assert_validation items: []
        assert_validation items: [nil]
        assert_validation items: [2234, 'foo', :bar]
      end

      def test_object_contents
        schema :array do
          hsh do
            str! :name
          end
        end

        assert_json(
          type:            :array,
          items:           {
            type:                 :object,
            properties:           { name: { type: :string } },
            required:             %i[name],
            additionalProperties: false
          },
          additionalItems: false
        )
        assert_validation [{ name: 'Foo' }, { name: 'Bar' }]
      end

      def test_type
        schema :array

        assert_json(type: :array)

        assert_validation 42 do
          error '/', EXP_INVALID_TYPE
        end

        schema { ary! :foo }

        assert_json(
          type:                 :object,
          properties:           {
            foo: { type: :array }
          },
          required:             %i[foo],
          additionalProperties: false
        )

        assert_validation foo: 42 do
          error '/foo', EXP_INVALID_TYPE
        end

        assert_validation foo: {} do
          error '/foo', EXP_INVALID_TYPE
        end
      end

      def test_min_items
        schema :array, min_items: 0

        assert_json(type: :array, minItems: 0)
        assert_validation []
        assert_validation [1]

        schema :array, min_items: 1

        assert_json(type: :array, minItems: 1)
        assert_validation [1]
        assert_validation [1, 2]
        assert_validation [] do
          error '/', 'Array has 0 items but needs at least 1.'
        end

        schema :array, min_items: 5
        assert_json(type: :array, minItems: 5)

        assert_validation [1, 2, 3, 4] do
          error '/', 'Array has 4 items but needs at least 5.'
        end
      end

      def test_max_items
        schema :array, max_items: 0

        assert_json(type: :array, maxItems: 0)
        assert_validation []

        schema :array, max_items: 1

        assert_json(type: :array, maxItems: 1)
        assert_validation [1]
        assert_validation [1, 2] do
          error '/', 'Array has 2 items but needs at most 1.'
        end

        schema :array, max_items: 5

        assert_json(type: :array, maxItems: 5)
        assert_validation [1, 2, 3, 4, 5, 6] do
          error '/', 'Array has 6 items but needs at most 5.'
        end
      end

      def test_min_max_items
        schema :array, min_items: 2, max_items: 4

        assert_json(type: :array, minItems: 2, maxItems: 4)
        assert_validation [1, 2]
        assert_validation [1, 2, 3]
        assert_validation [1, 2, 3, 4]

        assert_validation [1] do
          error '/', 'Array has 1 items but needs at least 2.'
        end

        assert_validation [1, 2, 3, 4, 5] do
          error '/', 'Array has 5 items but needs at most 4.'
        end
      end

      def test_unique_items
        schema :array, unique_items: true

        assert_json(type: :array, uniqueItems: true)
        assert_validation [1, 2]
        assert_validation [1, 2, :foo, 'bar', 'foo']

        assert_validation [1, 1] do
          error '/', 'Array has duplicate items.'
        end

        assert_validation [:foo, :foo] do
          error '/', 'Array has duplicate items.'
        end

        assert_validation [1, 2, :foo, 'bar', 'foo'].as_json do
          error '/', 'Array has duplicate items.'
        end
      end

      def test_single_item
        schema :array do
          str
        end

        assert_json(type: :array, items: { type: :string }, additionalItems: false)

        assert_validation []
        assert_validation %w[foo]
        assert_validation %w[foo bar]

        assert_validation ['foo', :bar] do
          error '/[1]', 'Invalid type, expected "string".'
        end

        assert_validation %i[foo bar] do
          error '/[0]', 'Invalid type, expected "string".'
          error '/[1]', 'Invalid type, expected "string".'
        end
      end

      def test_tuple
        schema :array do
          str
          int
          hsh do
            str! :name
          end
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string },
            { type: :integer },
            { type: :object, properties: { name: { type: :string } }, required: %i[name], additionalProperties: false }
          ],
          additionalItems: false
        )

        assert_validation(['foo', 42, { name: 'Hello' }])

        assert_validation [] do
          error '/', 'Array has 0 items but must have exactly 3.'
        end

        assert_validation ['foo'] do
          error '/', 'Array has 1 items but must have exactly 3.'
        end

        assert_validation([42, 42, { name: 'Hello' }]) do
          error '/[0]', 'Invalid type, expected "string".'
        end

        assert_validation(['foo', 42, { namex: 'Hello' }]) do
          error '/[2]/name', 'Value must be given.'
          error '/[2]', 'Obsolete property "namex".'
        end
      end

      def test_additional_items_true
        schema :array, additional_items: true do
          str
          int
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string },
            { type: :integer }
          ],
          additionalItems: true
        )

        assert_validation(['foo', 42])
        assert_validation(['foo', 42, 'additional'])
        assert_validation(['foo', 42, 42])

        assert_cast(['Foo', 42], ['Foo', 42])
        assert_cast(['Foo', 42, 42], ['Foo', 42, 42])
        assert_cast(['Foo', 42, :bar], ['Foo', 42, :bar])
      end

      def test_additional_items_true_casting
        schema :array, additional_items: true do
          str format: :date
          int
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string, format: :date },
            { type: :integer }
          ],
          additionalItems: true
        )

        assert_validation(['1990-01-01', 42])
        assert_validation(['1990-01-01', 42, 'additional'])
        assert_validation(['1990-01-01', 42, 42])

        assert_cast(['1990-01-01', 42], [Date.new(1990, 1, 1), 42])
        assert_cast(['1990-01-01', 42, '2010-01-01'], [Date.new(1990, 1, 1), 42, '2010-01-01'])
        assert_cast(['1990-01-01', 42, :bar], [Date.new(1990, 1, 1), 42, :bar])
      end

      def test_additional_items_schema
        schema :array, additional_items: true do
          str
          int
          add :string
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string },
            { type: :integer }
          ],
          additionalItems: { type: :string }
        )

        assert_validation(['foo', 42])
        assert_validation(['foo', 42, 'additional', 'another'])
        assert_validation(['foo', 42, 'additional', 42, 'another']) do
          error '/[3]', 'Invalid type, expected "string".'
        end

        assert_cast(['foo', 42], ['foo', 42])
        assert_cast(['foo', 42, 'bar'], ['foo', 42, 'bar'])
      end

      def test_additional_items_schema_casting
        schema :array, additional_items: true do
          str
          int
          add :string, format: :date
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string },
            { type: :integer }
          ],
          additionalItems: { type: :string, format: :date }
        )

        assert_validation(['foo', 42])
        assert_validation(['foo', 42, '1990-01-01'])
        assert_validation(['foo', 42, '1990-01-01', 42]) do
          error '/[3]', 'Invalid type, expected "string".'
        end
        assert_validation(['foo', 42, '1990-01-01', 'foo']) do
          error '/[3]', 'String does not match format "date".'
        end

        assert_cast(['foo', 42], ['foo', 42])
        assert_cast(['foo', 42, '1990-01-01'], ['foo', 42, Date.new(1990, 1, 1)])
      end

      def test_additional_items_schema_oneof_casting
        schema :array, additional_items: true do
          str
          int
          add :one_of do
            str format: :date
            str format: :integer
          end
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string },
            { type: :integer }
          ],
          additionalItems: {
            oneOf: [
              { type: :string, format: :date },
              { type: :string, format: :integer }
            ]
          }
        )

        assert_validation(['foo', 42])
        assert_validation(['foo', 42, '1990-01-01'])
        assert_validation(['foo', 42, '1990-01-01', 42]) do
          error '/[3]', 'Matches 0 definitions but should match exactly 1.'
        end
        assert_validation(['foo', 42, '1990-01-01', 'foo']) do
          error '/[3]', 'Matches 0 definitions but should match exactly 1.'
        end

        assert_cast(['foo', 42], ['foo', 42])
        assert_cast(['foo', 42, '1990-01-01'], ['foo', 42, Date.new(1990, 1, 1)])
        assert_cast(['foo', 42, '1337'], ['foo', 42, 1337])
      end

      def test_additional_items_schema_hash_casting
        schema :array, additional_items: true do
          str
          int
          add :hash do
            str! :foo, format: :date
            sym? :bar
          end
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string },
            { type: :integer }
          ],
          additionalItems: {
            properties:           {
              foo: {
                type:   :string,
                format: :date
              },
              bar: {}
            },
            additionalProperties: false,
            type:                 :object,
            required:             [
              :foo
            ]
          }
        )

        assert_validation(['foo', 42])
        assert_validation(['foo', 42, { foo: '1990-01-01' }])
        assert_validation(['foo', 42, { foo: '1990-01-01', bar: :baz }])

        assert_validation(['foo', 42, { foo: 1234 }]) do
          error '/[2]/foo', 'Invalid type, expected "string".'
        end
        assert_validation(['foo', 42, { foo: 'String' }]) do
          error '/[2]/foo', 'String does not match format "date".'
        end

        assert_cast(['foo', 42], ['foo', 42])
        assert_cast(['foo', 42, { foo: '1990-01-01' }], ['foo', 42, { foo: Date.new(1990, 1, 1) }])
        assert_cast(['foo', 42, { foo: '1990-01-01', bar: :baz }], ['foo', 42, { foo: Date.new(1990, 1, 1), bar: :baz }])
      end

      def test_multiple_add_in_schema
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'You can only use "add" once to specify additional items.' do
          schema :array do
            add :integer
            add :string
          end
        end
      end

      def test_contains
        schema :array, contains: true do
          str
        end

        assert_json(
          type:     :array,
          contains: {
            type: :string
          }
        )

        assert_validation(%w[foo bar])
        assert_validation(['foo', 42])
        assert_validation(['foo'])

        assert_validation([]) do
          error '/', 'At least one entry must match schema {"type"=>"string"}.'
        end

        assert_validation([234, :foo]) do
          error '/', 'At least one entry must match schema {"type"=>"string"}.'
        end
      end

      def test_contains_int
        schema :array, contains: true do
          int
        end

        assert_validation(['foo', 1, :bar])
        assert_cast(['foo', 1, :bar], ['foo', 1, :bar])
      end

      def test_contains_need_casting
        schema :array, contains: true do
          str format: :date
        end

        assert_validation(nil)
        assert_validation(['1990-01-01'])

        assert_cast(['1990-01-01'], [Date.new(1990, 1, 1)])
        assert_cast(%w[1990-01-01 123], [Date.new(1990, 1, 1), '123'])
        assert_cast(%w[1990-01-01 123 2010-01-01], [Date.new(1990, 1, 1), '123', Date.new(2010, 1, 1)])
      end

      def test_defaults
        schema :array, default: [1, 2, 3]

        assert_cast nil, [1, 2, 3]

        assert_json(
          type:    :array,
          default: [1, 2, 3]
        )

        schema :array do
          hsh do
            str? :name, default: 'John'
          end
        end

        assert_json(
          type:            :array,
          items:           {
            type:                 :object,
            properties:           {
              name: { type: :string, default: 'John' }
            },
            additionalProperties: false
          },
          additionalItems: false
        )

        assert_cast [{}], [{ name: 'John' }]
      end

      def test_enum_schema
        schema :array, enum: [1, 2, 'foo', :bar, { qux: 42 }, [1, 2], %w[a b]]

        assert_json({
                      type: :array,
                      enum: [1, 2, 'foo', :bar, { qux: 42 }, [1, 2], %w[a b]]
                    })

        assert_validation(nil)
        assert_validation([1, 2])
        assert_validation(%w[a b])

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not arrays
        assert_validation('foo') do
          error '/', 'Invalid type, expected "array".'
        end
        assert_validation(1) do
          error '/', 'Invalid type, expected "array".'
        end
        assert_validation(:bar) do
          error '/', 'Invalid type, expected "array".'
        end
        assert_validation({ qux: 42 }) do
          error '/', 'Invalid type, expected "array".'
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation([1, 2, 3]) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, [1, 2], ["a", "b"]].'
        end
        assert_validation([]) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, [1, 2], ["a", "b"]].'
        end
      end

      def test_with_generic_keywords
        schema :array, enum:        [1, 'foo', [1, 2, 3]],
                       title:       'Array schema',
                       description: 'Array schema holding generic keywords',
                       examples:    [
                         [1, 2, 3]
                       ]

        assert_json({
                      type:        :array,
                      enum:        [1, 'foo', [1, 2, 3]],
                      title:       'Array schema',
                      description: 'Array schema holding generic keywords',
                      examples:    [
                        [1, 2, 3]
                      ]
                    })
      end

      # Helper function that checks for the min_items and max_items options if the option is
      # an integer or something else, in which case it needs to raise
      def validate_self_should_error(value_to_check)
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "min_items" must be an "integer"' do
          schema :array, min_items: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "max_items" must be an "integer"' do
          schema :array, max_items: value_to_check
        end
      end

      def test_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "min_items" can\'t be greater than "max_items".' do
          schema :array, min_items: 5, max_items: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "unique_items" must be a "boolean".' do
          schema :array, unique_items: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "unique_items" must be a "boolean".' do
          schema :array, unique_items: 'false'
        end

        validate_self_should_error(1.0)
        validate_self_should_error(4r)
        validate_self_should_error(true)
        validate_self_should_error(false)
        validate_self_should_error(Object.new)
        validate_self_should_error((4 + 6i))
        validate_self_should_error('13')
        validate_self_should_error('Lorem ipsum')
      end
    end
  end
end
