require 'test_helper'

module Schemacop
  module V3
    class SymbolNodeTest < V3Test
      def self.invalid_type_error(type)
        type = type.class unless type.instance_of?(Class)
        "Invalid type, got type \"#{type}\", expected \"Symbol\"."
      end

      def test_basic
        schema :symbol

        assert_validation :foo
        assert_validation :'n0238n)Q(hqr3hrw3'
        assert_validation 42 do
          error '/', SymbolNodeTest.invalid_type_error(Integer)
        end
        assert_validation '42' do
          error '/', SymbolNodeTest.invalid_type_error(String)
        end
        assert_json({})
      end

      def test_required
        schema :symbol, required: true
        assert_validation :foo
        assert_validation :""
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
        schema(:array) do
          list :symbol
        end

        assert_validation %i[foo bar baz]
        assert_json(type: :array, items: {})
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
          error '/', SymbolNodeTest.invalid_type_error(String)
        end
        assert_validation(1) do
          error '/', SymbolNodeTest.invalid_type_error(Integer)
        end
        assert_validation({ qux: 42 }) do
          error '/', SymbolNodeTest.invalid_type_error(Hash)
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation(:foo) do
          error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
        end
      end

      # rubocop:disable Lint/BooleanSymbol
      def test_cast_str
        schema :symbol, cast_str: true

        assert_cast('true', :true)
        assert_cast('foo', :foo)
        assert_cast('1', :'1')

        assert_cast(:true, :true)
        assert_cast(:foo, :foo)
        assert_cast(:'1', :'1')
      end
      # rubocop:enable Lint/BooleanSymbol
    end
  end
end
