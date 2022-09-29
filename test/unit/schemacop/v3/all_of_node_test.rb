require 'test_helper'

module Schemacop
  module V3
    class AllOfNodeTest < V3Test
      def test_optional
        schema :all_of do
          str min_length: 2
          str max_length: 4
        end

        assert_validation(nil)
        assert_validation('12')
        assert_validation('1234')
        assert_validation('1') do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1:
                - /: String is 1 characters long but must be at least 2.
              - Schema 2: Matches
          PLAIN
        end
        assert_validation('12345') do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2:
                - /: String is 5 characters long but must be at most 4.
          PLAIN
        end
      end

      def test_required
        schema :all_of, required: true do
          int minimum: 2
          int maximum: 4
        end

        assert_validation(2)
        assert_validation(3)
        assert_validation(4)

        assert_validation(5) do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2:
                - /: Value must have a maximum of 4.
          PLAIN
        end
        assert_validation(1) do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1:
                - /: Value must have a minimum of 2.
              - Schema 2: Matches
          PLAIN
        end
        assert_validation({}) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match all of them:
              - Schema 1:
                - /: Invalid type, got type "Hash", expected "integer".
              - Schema 2:
                - /: Invalid type, got type "Hash", expected "integer".
          PLAIN
        end
        assert_validation(42) do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2:
                - /: Value must have a maximum of 4.
          PLAIN
        end
      end

      def test_nested
        schema :all_of do
          hsh additional_properties: true do
            all_of! :foo do
              int minimum: 2
              int maximum: 4
            end
          end
          hsh additional_properties: true do
            any_of! :bar do
              int minimum: 6
              int maximum: 8
            end
          end
        end

        assert_validation(foo: 2, bar: 7)
        assert_validation(foo: 5, bar: 7) do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1:
                - /foo: Matches 1 schemas but should match all of them:
                  - Schema 1: Matches
                  - Schema 2:
                    - /: Value must have a maximum of 4.
              - Schema 2: Matches
          PLAIN
        end
        assert_validation(foo: 5) do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match all of them:
              - Schema 1:
                - /foo: Matches 1 schemas but should match all of them:
                  - Schema 1: Matches
                  - Schema 2:
                    - /: Value must have a maximum of 4.
              - Schema 2:
                - /bar: Value must be given.
          PLAIN
        end
      end

      def test_simple_casting
        schema :all_of do
          str format: :integer
        end

        assert_validation(nil)
        assert_validation('1')
        assert_validation('Foo') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match all of them:
              - Schema 1:
                - /: String does not match format "integer".
          PLAIN
        end

        assert_cast('1', 1)
        assert_cast('1337', 1337)
      end

      def test_casting_with_conditions
        schema :all_of do
          str format:     :integer
          str min_length: 2
          str max_length: 3
        end

        assert_validation(nil)
        assert_validation('12')
        assert_validation('123')

        assert_validation('1') do
          error '/', <<~PLAIN.strip
            Matches 2 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2:
                - /: String is 1 characters long but must be at least 2.
              - Schema 3: Matches
          PLAIN
        end

        assert_validation('1234') do
          error '/', <<~PLAIN.strip
            Matches 2 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2: Matches
              - Schema 3:
                - /: String is 4 characters long but must be at most 3.
          PLAIN
        end
        assert_cast('42', 42)
      end

      def test_casting_with_conditions_changed_order
        schema :all_of do
          str min_length: 2
          str max_length: 3
          str format:     :integer
        end

        assert_validation(nil)
        assert_validation('12')
        assert_validation('123')

        assert_validation('1') do
          error '/', <<~PLAIN.strip
            Matches 2 schemas but should match all of them:
              - Schema 1:
                - /: String is 1 characters long but must be at least 2.
              - Schema 2: Matches
              - Schema 3: Matches
          PLAIN
        end

        assert_validation('1234') do
          error '/', <<~PLAIN.strip
            Matches 2 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2:
                - /: String is 4 characters long but must be at most 3.
              - Schema 3: Matches
          PLAIN
        end

        assert_cast('42', 42)
        assert_cast('123', 123)
      end

      def test_hash_casting
        schema :all_of do
          hsh additional_properties: true do
            str! :foo, format: :integer
          end
          hsh additional_properties: true do
            str! :bar, format: :date
          end
        end

        assert_validation(foo: '42', bar: '2020-01-15')

        assert_cast(
          { foo: '42', bar: '2020-01-15' },
          { foo: 42, bar: Date.new(2020, 1, 15) }.with_indifferent_access
        )
      end

      def test_nonsensical_casting
        schema :all_of do
          str format: :integer
          str format: :boolean
        end

        assert_validation(nil)
        assert_validation('42') do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1: Matches
              - Schema 2:
                - /: String does not match format "boolean".
          PLAIN
        end
        assert_validation('true') do
          error '/', <<~PLAIN.strip
            Matches 1 schemas but should match all of them:
              - Schema 1:
                - /: String does not match format "integer".
              - Schema 2: Matches
          PLAIN
        end
      end

      def test_defaults
        schema :all_of do
          str default: 'foobar'
        end

        assert_validation(nil)
        assert_validation('Hello World')

        assert_json({
                      allOf: [
                        type:    :string,
                        default: 'foobar'
                      ]
                    })
      end

      def test_with_generic_keywords
        schema :all_of, title:       'allOf schema',
                        description: 'allOf schema holding generic keywords',
                        examples:    [
                          'foo'
                        ]

        assert_json({
                      allOf:       [],
                      title:       'allOf schema',
                      description: 'allOf schema holding generic keywords',
                      examples:    [
                        'foo'
                      ]
                    })
      end
    end
  end
end
