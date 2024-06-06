require 'test_helper'

module Schemacop
  module V3
    class ArrayNodeTest < V3Test
      def self.invalid_type_error(type)
        "Invalid type, got type \"#{type}\", expected \"array\"."
      end

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

        assert_validation [{ name: 'Foo' }]
        assert_validation [{ name: 'Foo' }, { name: 'Bar' }] do
          error '/', 'Array has 2 items but must have exactly 1.'
        end
        assert_validation [123] do
          error '/[0]', 'Invalid type, got type "Integer", expected "object".'
        end
      end

      def test_type
        schema :array

        assert_json(type: :array)

        assert_validation 42 do
          error '/', ArrayNodeTest.invalid_type_error(Integer)
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
          error '/foo', ArrayNodeTest.invalid_type_error(Integer)
        end

        assert_validation foo: {} do
          error '/foo', ArrayNodeTest.invalid_type_error(ActiveSupport::HashWithIndifferentAccess)
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

      def test_single_item_tuple
        schema :array do
          str
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string }
          ],
          additionalItems: false
        )

        assert_validation [] do
          error '/', 'Array has 0 items but must have exactly 1.'
        end
        assert_validation %w[foo]
        assert_validation %w[foo bar] do
          error '/', 'Array has 2 items but must have exactly 1.'
        end

        assert_validation ['foo', :bar] do
          error '/', 'Array has 2 items but must have exactly 1.'
        end

        assert_validation %i[foo] do
          error '/[0]', 'Invalid type, got type "Symbol", expected "string".'
        end
      end

      def test_multiple_item_tuple
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
          error '/[0]', 'Invalid type, got type "Integer", expected "string".'
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

      def test_additional_items_single
        schema :array do
          str
          add :integer
        end

        assert_json(
          type:            :array,
          items:           [
            { type: :string }
          ],
          additionalItems: { type: :integer }
        )

        assert_validation(['foo'])
        assert_validation(['foo', 42])
        assert_validation(['foo', 42, 42])
        assert_validation(['foo', :foo]) do
          error '/[1]', 'Invalid type, got type "Symbol", expected "integer".'
        end
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
          error '/[3]', 'Invalid type, got type "Integer", expected "string".'
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
          error '/[3]', 'Invalid type, got type "Integer", expected "string".'
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
          error '/[3]', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "Integer", expected "string".
              - Schema 2:
                - /: Invalid type, got type "Integer", expected "string".
          PLAIN
        end
        assert_validation(['foo', 42, '1990-01-01', 'foo']) do
          error '/[3]', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: String does not match format "date".
              - Schema 2:
                - /: String does not match format "integer".
          PLAIN
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
          error '/[2]/foo', 'Invalid type, got type "Integer", expected "string".'
        end
        assert_validation(['foo', 42, { foo: 'String' }]) do
          error '/[2]/foo', 'String does not match format "date".'
        end

        assert_cast(['foo', 42], ['foo', 42])
        assert_cast(['foo', 42, { foo: '1990-01-01' }], ['foo', 42, { foo: Date.new(1990, 1, 1) }.with_indifferent_access])
        assert_cast(['foo', 42, { foo: '1990-01-01', bar: :baz }], ['foo', 42, { foo: Date.new(1990, 1, 1), bar: :baz }.with_indifferent_access])
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

      def test_reject_with_symbol
        schema :array, min_items: 3, max_items: 3, reject: :blank? do
          list :symbol
        end

        input = [:foo, :bar, :baz, :'']
        input_was = input.dup

        assert_validation(input)
        assert_cast(input, %i[foo bar baz])

        assert_equal input, input_was
      end

      def test_reject_with_proc
        schema :array, reject: ->(i) { i > 5 } do
          list :integer, maximum: 5
        end

        input = [1, 2, 3, 4, 5, 6]
        input_was = input.dup

        assert_validation(input)
        assert_cast(input, [1, 2, 3, 4, 5])

        assert_equal input, input_was
      end

      def test_reject_with_argument_error
        schema :array, reject: :zero? do
          list :integer
        end

        assert_validation([0, 1, 2, :a]) do
          error '/[2]', 'Invalid type, got type "Symbol", expected "integer".'
        end
      end

      def test_filter_with_symbol
        schema :array, min_items: 3, max_items: 3, filter: :present? do
          list :symbol
        end

        input = [:foo, :bar, :baz, :'']
        input_was = input.dup

        assert_validation(input)
        assert_cast(input, %i[foo bar baz])

        assert_equal input, input_was
      end

      def test_filter_with_proc
        schema :array, filter: ->(i) { i <= 5 } do
          list :integer, maximum: 5
        end

        input = [1, 2, 3, 4, 5, 6]
        input_was = input.dup

        assert_validation(input)
        assert_cast(input, [1, 2, 3, 4, 5])

        assert_equal input, input_was
      end

      def test_filter_with_argument_error
        schema :array, filter: :nonzero? do
          list :integer
        end

        assert_validation([0, 1, 2, :a]) do
          error '/[2]', 'Invalid type, got type "Symbol", expected "integer".'
        end
      end

      def test_doc_example_reject_blank
        # FYI: This example requires active_support for the blank? method
        schema = Schemacop::Schema3.new :array, reject: :blank? do
          list :string
        end

        assert_equal ['foo'], schema.validate!(['', 'foo'])
      end

      def test_doc_example_filter_proc
        schema = Schemacop::Schema3.new :array, filter: ->(value) { value.is_a?(String) } do
          list :string
        end

        assert_equal ['foo'], schema.validate!(['foo', 42])
      end

      def test_doc_example_reject_zero
        schema = Schemacop::Schema3.new :array, reject: :zero? do
          list :integer
        end

        assert_raises_with_message(
          Schemacop::Exceptions::ValidationError,
          '/[0]: Invalid type, got type "String", expected "integer".'
        ) do
          schema.validate!(['foo', 42, 0])
        end
      end

      def test_contains
        schema :array do
          cont :string
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
        schema :array do
          cont :integer
        end

        assert_validation(['foo', 1, :bar])
        assert_cast(['foo', 1, :bar], ['foo', 1, :bar])
      end

      def test_contains_with_casting
        schema :array do
          cont :string, format: :date
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

        assert_cast [{}], [{ name: 'John' }.with_indifferent_access]
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
          error '/', ArrayNodeTest.invalid_type_error(String)
        end
        assert_validation(1) do
          error '/', ArrayNodeTest.invalid_type_error(Integer)
        end
        assert_validation(:bar) do
          error '/', ArrayNodeTest.invalid_type_error(Symbol)
        end
        assert_validation({ qux: 42 }) do
          error '/', ArrayNodeTest.invalid_type_error(Hash)
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

      def test_list
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'You can only use "list" once.' do
          schema :array do
            list :integer
            list :symbol
          end
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Can\'t use "list" and normal items.' do
          schema :array do
            list :integer
            int
          end
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Can\'t use "list" and additional items.' do
          schema :array do
            list :integer
            add :symbol
          end
        end

        schema :array do
          list :integer
        end

        assert_validation([])
        assert_validation([1])
        assert_validation([1, 2, 3, 4, 5, 6])

        assert_validation([1, :foo, 'bar']) do
          error '/[1]', 'Invalid type, got type "Symbol", expected "integer".'
          error '/[2]', 'Invalid type, got type "String", expected "integer".'
        end
      end

      def test_list_casting
        schema :array do
          list :string, format: :date
        end

        assert_json(
          type:  :array,
          items: {
            type:   :string,
            format: :date
          }
        )

        assert_validation(nil)
        assert_validation(['1990-01-01'])
        assert_validation(%w[1990-01-01 2020-01-01])
        assert_validation(['foo']) do
          error '/[0]', 'String does not match format "date".'
        end

        assert_cast(['1990-01-01'], [Date.new(1990, 1, 1)])
      end

      def test_simple_contains
        schema :array do
          cont :integer, minimum: 3
        end

        assert_json(
          type:     :array,
          contains: {
            type:    :integer,
            minimum: 3
          }
        )

        assert_validation(nil)
        assert_validation([]) do
          error '/', 'At least one entry must match schema {"type"=>"integer", "minimum"=>3}.'
        end
        assert_validation([1, 2]) do
          error '/', 'At least one entry must match schema {"type"=>"integer", "minimum"=>3}.'
        end
        assert_validation([1, 2, 3])
      end

      def test_contains_with_list
        schema :array do
          list :integer, minimum: 2
          cont :integer, minimum: 5
        end

        assert_json(
          type:     :array,
          contains: {
            type:    :integer,
            minimum: 5
          },
          items:    {
            type:    :integer,
            minimum: 2
          }
        )

        assert_validation(nil)
        assert_validation([]) do
          error '/', 'At least one entry must match schema {"type"=>"integer", "minimum"=>5}.'
        end
        assert_validation([1]) do
          error '/', 'At least one entry must match schema {"type"=>"integer", "minimum"=>5}.'
          error '/[0]', 'Value must have a minimum of 2.'
        end
        assert_validation([2]) do
          error '/', 'At least one entry must match schema {"type"=>"integer", "minimum"=>5}.'
        end

        assert_validation([2, 3, 5])
      end

      def test_contains_need_casting
        schema :array do
          cont :string, format: :date
        end

        assert_json(
          type:     :array,
          contains: {
            type:   :string,
            format: :date
          }
        )

        assert_validation(nil)
        assert_validation(['1990-01-01'])
        assert_validation(['1990-01-01', 1234])

        assert_cast(['1990-01-01'], [Date.new(1990, 1, 1)])
        assert_cast(%w[1990-01-01 123], [Date.new(1990, 1, 1), '123'])
        assert_cast(%w[1990-01-01 123 2010-01-01], [Date.new(1990, 1, 1), '123', Date.new(2010, 1, 1)])
      end

      def test_contains_with_list_casting
        schema :array do
          list :string
          cont :string, format: :date
        end

        assert_json(
          type:     :array,
          items:    {
            type: :string
          },
          contains: {
            type:   :string,
            format: :date
          }
        )

        assert_validation(nil)
        assert_validation(['foo']) do
          error '/', 'At least one entry must match schema {"type"=>"string", "format"=>"date"}.'
        end
        assert_validation(%w[foo 1990-01-01])

        assert_cast(%w[foo 1990-01-01], ['foo', Date.new(1990, 1, 1)])
      end

      def test_contains_multiple_should_fail
        assert_raises_with_message Exceptions::InvalidSchemaError, 'You can only use "cont" once.' do
          schema :array do
            list :string
            cont :string
            cont :integer
          end
        end
      end

      def test_parse_json
        schema :array, parse_json: true do
          list :integer
        end
        assert_validation([1, 2, 3])
        assert_validation('[1,2,3]')
        assert_cast('[1,2,3]', [1, 2, 3])

        assert_validation('[1,2,"3"]') do
          error '/[2]', 'Invalid type, got type "String", expected "integer".'
        end

        assert_validation('{ "id": 42 }') do
          error '/', 'Invalid type, got type "Hash", expected "array".'
        end

        assert_validation('{42]') do
          error '/', /JSON parse error: "(\d+: )?unexpected token at '{42]'"\./
        end

        assert_validation('"foo"') do
          error '/', 'Invalid type, got type "String", expected "array".'
        end
      end
    end
  end
end
