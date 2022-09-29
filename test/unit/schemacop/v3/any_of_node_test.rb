require 'test_helper'

module Schemacop
  module V3
    class AnyOfNodeTest < V3Test
      def test_optional
        schema :any_of do
          str
          int
        end

        assert_validation(nil)
        assert_validation('string')
        assert_validation(42)
        assert_validation(42.1) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /: Invalid type, got type "Float", expected "string".
              - Schema 2:
                - /: Invalid type, got type "Float", expected "integer".
          PLAIN
        end
        assert_validation({}) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /: Invalid type, got type "Hash", expected "string".
              - Schema 2:
                - /: Invalid type, got type "Hash", expected "integer".
          PLAIN
        end
      end

      def test_required
        schema :any_of, required: true do
          str
          int
        end

        assert_validation('string')
        assert_validation(42)

        assert_validation(nil) do
          error '/', 'Value must be given.'
        end

        assert_validation(42.1) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /: Invalid type, got type "Float", expected "string".
              - Schema 2:
                - /: Invalid type, got type "Float", expected "integer".
          PLAIN
        end
        assert_validation({}) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /: Invalid type, got type "Hash", expected "string".
              - Schema 2:
                - /: Invalid type, got type "Hash", expected "integer".
          PLAIN
        end
      end

      def test_nested
        schema :any_of do
          hsh do
            any_of! :foo do
              int
              str
            end
          end
          int
        end

        assert_validation(nil)
        assert_validation(42)
        assert_validation(foo: 42)
        assert_validation(foo: 'str')
        assert_validation('string') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "object".
              - Schema 2:
                - /: Invalid type, got type "String", expected "integer".
          PLAIN
        end
        assert_validation(bar: :baz) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /foo: Value must be given.
                - /: Obsolete property "bar".
              - Schema 2:
                - /: Invalid type, got type "Hash", expected "integer".
          PLAIN
        end
        assert_validation(foo: :bar) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
              - Schema 1:
                - /foo: Matches 0 schemas but should match at least 1:
                  - Schema 1:
                    - /: Invalid type, got type "Symbol", expected "integer".
                  - Schema 2:
                    - /: Invalid type, got type "Symbol", expected "string".
              - Schema 2:
                - /: Invalid type, got type "Hash", expected "integer".
          PLAIN
        end
      end

      def test_all_types
        schema :any_of do
          all_of do
            hsh { str! :foo }
          end
          any_of do
            obj classes: Date
            obj classes: Time
          end
          ary
          boo
          int
          num
          hsh { int! :bar }
          one_of do
            hsh { str! :a, pattern: '^a' }
            hsh { str! :a, pattern: 'z$' }
          end
          ref :MyDate
          str max_length: 2
        end

        context = Context.new
        context.schema :MyDate, :string, format: :date

        Schemacop.with_context context do
          assert_validation(nil)
          assert_validation(foo: 'str')
          assert_validation([1, 2, 3])
          assert_validation(true)
          assert_validation(false)
          assert_validation(42)
          assert_validation(42.2)
          assert_validation(bar: 42)
          assert_validation(a: 'a hello')
          assert_validation(a: 'hello z')
          assert_validation('1990-01-13')
          assert_validation('12')
          assert_validation(Date.new(1990, 1, 13))
          assert_validation(Time.now)

          assert_validation('1990-01-13 12') do
            error '/', <<~PLAIN.strip
              Matches 0 schemas but should match at least 1:
                - Schema 1:
                  - /: Matches 0 schemas but should match all of them:
                    - Schema 1:
                      - /: Invalid type, got type "String", expected "object".
                - Schema 2:
                  - /: Matches 0 schemas but should match at least 1:
                    - Schema 1:
                      - /: Invalid type, got type "String", expected "Date".
                    - Schema 2:
                      - /: Invalid type, got type "String", expected "Time".
                - Schema 3:
                  - /: Invalid type, got type "String", expected "array".
                - Schema 4:
                  - /: Invalid type, got type "String", expected "boolean".
                - Schema 5:
                  - /: Invalid type, got type "String", expected "integer".
                - Schema 6:
                  - /: Invalid type, got type "String", expected "big_decimal" or "float" or "integer" or "rational".
                - Schema 7:
                  - /: Invalid type, got type "String", expected "object".
                - Schema 8:
                  - /: Matches 0 schemas but should match exactly 1:
                    - Schema 1:
                      - /: Invalid type, got type "String", expected "object".
                    - Schema 2:
                      - /: Invalid type, got type "String", expected "object".
                - Schema 9:
                  - /: String does not match format "date".
                - Schema 10:
                  - /: String is 13 characters long but must be at most 2.
            PLAIN
          end
          assert_validation(a: 'a hello z') do
            error '/', <<~PLAIN.strip
              Matches 0 schemas but should match at least 1:
                - Schema 1:
                  - /: Matches 0 schemas but should match all of them:
                    - Schema 1:
                      - /foo: Value must be given.
                      - /: Obsolete property "a".
                - Schema 2:
                  - /: Matches 0 schemas but should match at least 1:
                    - Schema 1:
                      - /: Invalid type, got type "Hash", expected "Date".
                    - Schema 2:
                      - /: Invalid type, got type "Hash", expected "Time".
                - Schema 3:
                  - /: Invalid type, got type "Hash", expected "array".
                - Schema 4:
                  - /: Invalid type, got type "Hash", expected "boolean".
                - Schema 5:
                  - /: Invalid type, got type "Hash", expected "integer".
                - Schema 6:
                  - /: Invalid type, got type "Hash", expected "big_decimal" or "float" or "integer" or "rational".
                - Schema 7:
                  - /bar: Value must be given.
                  - /: Obsolete property "a".
                - Schema 8:
                  - /: Matches 2 schemas but should match exactly 1:
                    - Schema 1: Matches
                    - Schema 2: Matches
                - Schema 9:
                  - /: Invalid type, got type "Hash", expected "string".
                - Schema 10:
                  - /: Invalid type, got type "Hash", expected "string".
            PLAIN
          end
          assert_validation(Object.new) do
            error '/', <<~PLAIN.strip
              Matches 0 schemas but should match at least 1:
                - Schema 1:
                  - /: Matches 0 schemas but should match all of them:
                    - Schema 1:
                      - /: Invalid type, got type "Object", expected "object".
                - Schema 2:
                  - /: Matches 0 schemas but should match at least 1:
                    - Schema 1:
                      - /: Invalid type, got type "Object", expected "Date".
                    - Schema 2:
                      - /: Invalid type, got type "Object", expected "Time".
                - Schema 3:
                  - /: Invalid type, got type "Object", expected "array".
                - Schema 4:
                  - /: Invalid type, got type "Object", expected "boolean".
                - Schema 5:
                  - /: Invalid type, got type "Object", expected "integer".
                - Schema 6:
                  - /: Invalid type, got type "Object", expected "big_decimal" or "float" or "integer" or "rational".
                - Schema 7:
                  - /: Invalid type, got type "Object", expected "object".
                - Schema 8:
                  - /: Matches 0 schemas but should match exactly 1:
                    - Schema 1:
                      - /: Invalid type, got type "Object", expected "object".
                    - Schema 2:
                      - /: Invalid type, got type "Object", expected "object".
                - Schema 9:
                  - /: Invalid type, got type "Object", expected "string".
                - Schema 10:
                  - /: Invalid type, got type "Object", expected "string".
            PLAIN
          end
        end
      end

      def test_casting
        schema do
          any_of! :created_at do
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
          any_of! :foo do
            hsh { str? :bar }
            hsh { str? :baz, default: 'Baz' }
          end
        end

        assert_validation(foo: { bar: 'Bar' })
        assert_validation(foo: { baz: 'Baz' })

        assert_validation(foo: { xyz: 'Baz' }) do
          error '/foo', <<~PLAIN.strip
            Matches 0 schemas but should match at least 1:
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
          any_of! :foo do
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
        schema :any_of, title:       'anyOf schema',
                        description: 'anyOf schema holding generic keywords',
                        examples:    [
                          'foo'
                        ] do
                          str
                          int
                        end

        assert_json({
                      anyOf:       [
                        { type: :string },
                        { type: :integer }
                      ],
                      title:       'anyOf schema',
                      description: 'anyOf schema holding generic keywords',
                      examples:    [
                        'foo'
                      ]
                    })
      end

      def test_invalid_schema
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Node "any_of" makes only sense with at least 1 item.' do
          schema :any_of
        end
      end
    end
  end
end
