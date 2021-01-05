require 'test_helper'

module Schemacop
  module V3
    class SymbolNodeTest < V3Test
      EXP_INVALID_TYPE = 'Invalid type, expected "Symbol".'.freeze

      def test_basic
        schema :symbol

        assert_validation :foo
        assert_validation :'n0238n)Q(hqr3hrw3'
        assert_validation 42 do
          error '/', EXP_INVALID_TYPE
        end
        assert_validation '42' do
          error '/', EXP_INVALID_TYPE
        end
        assert_json({})
      end

      def test_required
        schema :symbol, required: true
        assert_validation :foo
        assert_validation ''.to_sym
        assert_validation nil do
          error '/', 'Value must be given.'
        end
      end

      def test_hash
        schema { sym! :name }
        assert_validation name: :foo
        assert_json(type: :object, properties: { name: {} }, required: %i[name], additionalProperties: false)
      end

      def test_array
        schema(:array) { sym }
        assert_validation %i[foo bar baz]
        assert_json(type: :array, items: {}, additionalItems: false)
      end

      def test_enum_schema
        schema :symbol, enum: [1, 2, 'foo', :bar, { qux: 42 }]

        # For symbol nodes, json representation is an empty hash, as we can't
        # repsresent symbols in json
        assert_json({})

        assert_validation(nil)
        assert_validation(:bar)

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not symbols
        assert_validation('foo') do
          error '/', 'Invalid type, expected "Symbol".'
        end
        assert_validation(1) do
          error '/', 'Invalid type, expected "Symbol".'
        end
        assert_validation({ qux: 42 }) do
          error '/', 'Invalid type, expected "Symbol".'
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation(:foo) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
        end
      end
    end
  end
end
