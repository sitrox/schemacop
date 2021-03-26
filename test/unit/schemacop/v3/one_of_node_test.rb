require 'test_helper'

module Schemacop
  module V3
    class OneOfNodeTest < V3Test
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
          error '/', 'Matches 2 definitions but should match exactly 1.'
        end
        assert_validation(1) do
          error '/', 'Matches 0 definitions but should match exactly 1.'
        end
        assert_validation(:foo) do
          error '/', 'Matches 0 definitions but should match exactly 1.'
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
          error '/', 'Matches 2 definitions but should match exactly 1.'
        end
        assert_validation(foo: 12) do
          error '/', 'Matches 0 definitions but should match exactly 1.'
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
          error '/foo', 'Matches 0 definitions but should match exactly 1.'
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
    end
  end
end
