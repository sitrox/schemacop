require 'test_helper'

module Schemacop
  module V3
    class IsNotNodeTest < V3Test
      def test_optional
        schema :is_not do
          int minimum: 5
        end

        assert_json(
          not: { type: :integer, minimum: 5 }
        )

        assert_validation(nil)
        assert_validation({})
        assert_validation(:foo)
        assert_validation(4)
        assert_validation(8) do
          error '/', 'Must not match schema: {"type"=>"integer", "minimum"=>5}.'
        end
      end

      def test_required
        schema :is_not, required: true do
          int minimum: 5
        end

        assert_json(
          not: { type: :integer, minimum: 5 }
        )

        assert_validation(:foo)
        assert_validation(4)
        assert_validation(nil) do
          error '/', 'Value must be given.'
        end
        assert_validation({})
        assert_validation(8) do
          error '/', 'Must not match schema: {"type"=>"integer", "minimum"=>5}.'
        end
      end

      def test_enum_schema
        schema :is_not do
          str enum: ['bar', 'qux', 123, :faz]
        end

        assert_json({
                      not: {
                        type: :string,
                        enum: ['bar', 'qux', 123, :faz]
                      }
                    })
        assert_validation(nil)
        assert_validation({ foo: 'bar' })
        assert_validation('baz')
        assert_validation(123)
        assert_validation(:faz)

        # Needs to fail the validation, as the value is included in the enum
        # and a string (which the not turns into "failing the validation")
        assert_validation('bar') do
          error '/', 'Must not match schema: {"type"=>"string", "enum"=>["bar", "qux", 123, "faz"]}.'
        end

        assert_validation('qux') do
          error '/', 'Must not match schema: {"type"=>"string", "enum"=>["bar", "qux", 123, "faz"]}.'
        end
      end

      def test_with_generic_keywords
        schema :is_not do
          str enum: ['bar', 'qux', 123, :faz], title: 'Short title', description: 'Longer description', examples: ['foo']
        end

        assert_json({
                      not: {
                        type:        :string,
                        enum:        ['bar', 'qux', 123, :faz],
                        title:       'Short title',
                        description: 'Longer description',
                        examples:    ['foo']
                      }
                    })

        # rubocop:disable Layout/LineLength

        # Needs to fail the validation, as the value is included in the enum
        # and a string (which the not turns into "failing the validation")
        assert_validation('bar') do
          error '/', 'Must not match schema: {"type"=>"string", "title"=>"Short title", "examples"=>["foo"], "description"=>"Longer description", "enum"=>["bar", "qux", 123, "faz"]}.'
        end

        assert_validation('qux') do
          error '/', 'Must not match schema: {"type"=>"string", "title"=>"Short title", "examples"=>["foo"], "description"=>"Longer description", "enum"=>["bar", "qux", 123, "faz"]}.'
        end

        # rubocop:enable Layout/LineLength
      end

      def test_not_object_json
        schema :is_not do
          hsh do
            int! :foo
            str! :bar
            add :integer
          end
        end

        assert_json(
          not: {
            properties:           {
              foo: {
                type: :integer
              },
              bar: {
                type: :string
              }
            },
            additionalProperties: {
              type: :integer
            },
            required:             %i[foo bar],
            type:                 :object
          }
        )
      end

      def test_not_array
        schema :is_not do
          ary do
            list :integer
          end
        end

        assert_validation(nil)
        assert_validation([]) do
          error '/', 'Must not match schema: {"type"=>"array", "items"=>{"type"=>"integer"}}.'
        end
        assert_validation('foo')
        assert_validation(['foo'])
        assert_validation([1]) do
          error '/', 'Must not match schema: {"type"=>"array", "items"=>{"type"=>"integer"}}.'
        end
      end

      def test_invalid_schema
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Node "is_not" only allows exactly one item.' do
          schema :is_not do
            int
            str
          end
        end
      end

      def test_casting
        schema :is_not do
          str format: :date
        end

        assert_validation(nil)
        assert_validation([])
        assert_validation(:bar)

        assert_cast([], [])
        assert_cast(1, 1)
        assert_cast({ foo: :bar, baz: 'Str' }, { foo: :bar, baz: 'Str' })
      end
    end
  end
end
