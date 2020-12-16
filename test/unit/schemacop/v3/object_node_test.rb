require 'test_helper'

module Schemacop
  module V3
    class ObjectNodeTest < V3Test
      def test_basic
        schema :object

        assert_validation nil
        assert_validation true
        assert_validation false
        assert_validation Object.new
        assert_validation 'foo'

        assert_json({})
      end

      def test_required_with_no_types
        schema :object, required: true

        assert_validation nil do
          error '/', 'Value must be given.'
        end
      end

      def test_with_classes
        schema :object, classes: [String, Date]
        assert_validation 'foo'
        assert_validation Date.today
        assert_validation({}.with_indifferent_access) do
          error '/', 'Invalid type, expected "Date" or "String".'
        end
        assert_validation DateTime.now do
          error '/', 'Invalid type, expected "Date" or "String".'
        end
      end

      def test_non_strict
        schema :object, classes: [String, Date, Hash], strict: false
        assert_validation 'foo'
        assert_validation 'foo'.html_safe
        assert_validation Date.today
        assert_validation nil
        assert_validation DateTime.now
        assert_validation({}.with_indifferent_access)
        assert_validation Time.now do
          error '/', 'Invalid type, expected "Date" or "Hash" or "String".'
        end
      end

      def test_required
        schema :object, required: true

        assert_validation true
        assert_validation false
        assert_validation nil do
          error '/', 'Value must be given.'
        end
      end

      def test_hash
        schema { obj! :myobj, String }
        assert_json(
          type:                 :object,
          properties:           {
            myobj: {}
          },
          required:             %i[myobj],
          additionalProperties: false
        )
        assert_validation myobj: ''
        assert_validation myobj: '42'
        assert_validation myobj: Date.today do
          error '/myobj', 'Invalid type, expected "String".'
        end
        assert_validation({}) do
          error '/myobj', 'Value must be given.'
        end
      end
    end
  end
end
