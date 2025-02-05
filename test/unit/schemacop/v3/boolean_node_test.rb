require 'test_helper'
# rubocop:disable Lint/BooleanSymbol

module Schemacop
  module V3
    class BooleanNodeTest < V3Test
      def self.invalid_type_error(type)
        type = type.class unless type.instance_of?(Class)
        "Invalid type, got type \"#{type}\", expected \"boolean\"."
      end

      def test_basic
        schema :boolean

        assert_validation true
        assert_validation false

        assert_json(type: :boolean)
      end

      def test_required_default
        schema do
          boo? :enabled, default: true
        end

        assert_validation(enabled: true)
        assert_validation(enabled: false)

        assert_cast({}, { 'enabled' => true })

        schema do
          boo? :enabled, default: false
        end

        assert_validation(enabled: true)
        assert_validation(enabled: false)

        assert_cast({}, { 'enabled' => false })
      end

      def test_default_bug
        schema do
          str! :send_message
          boo? :always_show_successful, default: true
        end

        assert_cast(
          { 'send_message' => 'foo' },
          { 'send_message' => 'foo', 'always_show_successful' => true }
        )
      end

      def test_required
        schema :boolean, required: true

        assert_validation true
        assert_validation false
        assert_validation nil do
          error '/', 'Value must be given.'
        end

        assert_json(type: :boolean)
      end

      def test_hash
        schema { boo! :alive }
        assert_json(
          type:                 :object,
          properties:           {
            alive: { type: :boolean }
          },
          required:             %i[alive],
          additionalProperties: false
        )
        assert_validation alive: true
        assert_validation alive: false
      end

      def test_type
        schema :boolean

        assert_json(type: :boolean)

        assert_validation 42 do
          error '/', BooleanNodeTest.invalid_type_error(Integer)
        end

        [:true, 'true', :false, 'false', 0, 1].each do |value|
          assert_validation value do
            error '/', BooleanNodeTest.invalid_type_error(value)
          end
        end

        schema { boo? :name }

        assert_json(
          type:                 :object,
          properties:           {
            name: { type: :boolean }
          },
          additionalProperties: false
        )

        [:true, 'true', :false, 'false', 0, 1].each do |value|
          assert_validation name: value do
            error '/name', BooleanNodeTest.invalid_type_error(value)
          end
        end
      end

      def test_enum_schema
        schema :boolean, enum: [1, 2, 'foo', :bar, { qux: 42 }, true]

        assert_json({
                      type: :boolean,
                      enum: [1, 2, 'foo', :bar, { qux: 42 }, true]
                    })

        assert_validation(nil)
        assert_validation(true)

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not booleans
        assert_validation('foo') do
          error '/', BooleanNodeTest.invalid_type_error(String)
        end
        assert_validation(:bar) do
          error '/', BooleanNodeTest.invalid_type_error(Symbol)
        end
        assert_validation({ qux: 42 }) do
          error '/', BooleanNodeTest.invalid_type_error(Hash)
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation(false) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}, true].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, true].'
          end
        end
      end

      def test_with_generic_keywords
        schema :boolean, enum:        [1, 'foo', true],
                         title:       'Boolean schema',
                         description: 'Boolean schema holding generic keywords',
                         examples:    [
                           true
                         ]

        assert_json({
                      type:        :boolean,
                      enum:        [1, 'foo', true],
                      title:       'Boolean schema',
                      description: 'Boolean schema holding generic keywords',
                      examples:    [
                        true
                      ]
                    })
      end

      def test_cast
        schema :boolean

        assert_cast(true, true)
        assert_cast(false, false)
        assert_cast(nil, nil)
      end

      def test_cast_default
        schema :boolean, default: true

        assert_cast(true, true)
        assert_cast(false, false)
        assert_cast(nil, true)
      end

      def test_cast_str
        schema :boolean, cast_str: true

        assert_cast('true', true)
        assert_cast('false', false)

        assert_cast('1', true)
        assert_cast('0', false)

        assert_cast(true, true)
        assert_cast(false, false)

        assert_cast('True', true)
        assert_cast('False', false)

        assert_validation('5') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "boolean".
              - Schema 2:
                - /: String does not match format "boolean".
          PLAIN
        end

        # Nil can be validated, as it's not required
        assert_validation(nil)

        assert_validation('')

        assert_cast('', nil)
        assert_cast(nil, nil)
      end

      def test_cast_str_required
        schema :boolean, cast_str: true, required: true

        assert_cast('true', true)
        assert_cast('false', false)

        assert_cast(true, true)
        assert_cast(false, false)

        # Test case-insentiveness
        assert_cast('True', true)
        assert_cast('False', false)

        assert_cast('TRUE', true)
        assert_cast('FALSE', false)

        assert_validation('4') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "boolean".
              - Schema 2:
                - /: String does not match format "boolean".
          PLAIN
        end

        assert_validation('foo') do
          error '/', <<~PLAIN.strip
            Matches 0 schemas but should match exactly 1:
              - Schema 1:
                - /: Invalid type, got type "String", expected "boolean".
              - Schema 2:
                - /: String does not match format "boolean".
          PLAIN
        end

        assert_validation(nil) do
          error '/', 'Value must be given.'
        end

        assert_validation('') do
          error '/', 'Value must be given.'
        end
      end
    end
  end
end
# rubocop:enable Lint/BooleanSymbol
