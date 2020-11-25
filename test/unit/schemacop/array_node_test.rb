require 'test_helper'

module Schemacop
  class ArrayNodeTest < V3Test
    EXP_INVALID_TYPE = 'Invalid type, expected "array".'.freeze

    def test_basic
      schema :array
      assert_json(type: :array)
      assert_validation []
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
      assert_validation items: [2234, 'foo', :bar]
    end

    def test_object_contents
      schema :array do
        obj do
          str! :name
        end
      end

      assert_json(
        type:            :array,
        items:           [
          {
            type:                 :object,
            properties:           { name: { type: :string } },
            required:             %i[name],
            additionalProperties: false
          }
        ],
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

      assert_json(type: :array, items: [{ type: :string }], additionalItems: false)

      assert_validation []
      assert_validation %w[foo]
      assert_validation %w[foo bar]

      assert_validation %i[foo bar] do
        error '/[0]', 'Invalid type, expected "string".'
        error '/[1]', 'Invalid type, expected "string".'
      end
    end

    def test_tuple
      schema :array do
        str
        int
        obj do
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

    def test_defaults
      schema :array, default: [1, 2, 3]

      assert_cast nil, [1, 2, 3]

      assert_json(
        type:    :array,
        default: [1, 2, 3]
      )

      schema :array do
        obj do
          str? :name, default: 'John'
        end
      end

      assert_json(
        type:            :array,
        items:           [
          {
            type:                 :object,
            properties:           {
              name: { type: :string, default: 'John' }
            },
            additionalProperties: false
          }
        ],
        additionalItems: false
      )

      assert_cast [{}], [{ name: 'John' }]
    end
  end
end
