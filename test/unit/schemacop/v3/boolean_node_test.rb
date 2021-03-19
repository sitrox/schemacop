require 'test_helper'
# rubocop:disable Lint/BooleanSymbol

module Schemacop
  module V3
    class BooleanNodeTest < V3Test
      def self.invalid_type_error(type)
        type = type.class unless type.class == Class
        "Invalid type, got type \"#{type}\", expected \"boolean\"."
      end

      def test_basic
        schema :boolean

        assert_validation true
        assert_validation false

        assert_json(type: :boolean)
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
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}, true].'
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

        assert_cast(true, true)
        assert_cast(false, false)

        assert_validation('1') do
          error '/', 'Matches 0 definitions but should match exactly 1.'
        end
      end
    end
  end
end
# rubocop:enable Lint/BooleanSymbol
