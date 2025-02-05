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
          error '/', 'Invalid type, got type "ActiveSupport::HashWithIndifferentAccess", expected "Date" or "String".'
        end
        assert_validation DateTime.now do
          error '/', 'Invalid type, got type "DateTime", expected "Date" or "String".'
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
          error '/', 'Invalid type, got type "Time", expected "Date" or "Hash" or "String".'
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
        schema do
          obj! :myobj, classes: String
        end

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
          error '/myobj', 'Invalid type, got type "Date", expected "String".'
        end
        assert_validation({}) do
          error '/myobj', 'Value must be given.'
        end
      end

      def test_hash_no_class
        schema do
          obj! :myobj
        end

        assert_validation(myobj: 'str')
        assert_validation(myobj: 123)
        assert_validation(myobj: Object.new)
      end

      def test_enum_schema
        schema :object, enum: [true, 'foo', :baz, [], { qux: '123' }]

        # Can't represent a Ruby Object as a JSON value
        assert_json({})

        # As we didn't provide any classes, any object (i.e. everything) will
        # be validated. However, only those elements we put into the enum list
        # will be allowed
        assert_validation(nil)
        assert_validation(true)
        assert_validation('foo')
        assert_validation(:baz)
        assert_validation([])
        assert_validation({ qux: '123' })

        # These will fail, as we didn't put them into the enum list
        assert_validation(1) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [true, "foo", :baz, [], {qux: "123"}].'
          else
            error '/', 'Value not included in enum [true, "foo", :baz, [], {:qux=>"123"}].'
          end
        end
        assert_validation(:bar) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [true, "foo", :baz, [], {qux: "123"}].'
          else
            error '/', 'Value not included in enum [true, "foo", :baz, [], {:qux=>"123"}].'
          end
        end
        assert_validation({ qux: 42 }) do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [true, "foo", :baz, [], {qux: "123"}].'
          else
            error '/', 'Value not included in enum [true, "foo", :baz, [], {:qux=>"123"}].'
          end
        end
      end

      def test_enum_schema_with_classes
        schema :object, classes: [String, Symbol, TrueClass], enum: [true, 'foo', :baz, [], { qux: '123' }, false]

        # Can't represent a Ruby Object as a JSON value
        assert_json({})

        # Values need to be one of the classed we defined above, as well as in the
        # enum list for the validation to pass
        assert_validation(nil)
        assert_validation(true)
        assert_validation('foo')
        assert_validation(:baz)

        # These will fail, as they aren't of one of the classed we defined above
        assert_validation([]) do
          error '/', 'Invalid type, got type "Array", expected "String" or "Symbol" or "TrueClass".'
        end
        assert_validation({ qux: '123' }) do
          error '/', 'Invalid type, got type "Hash", expected "String" or "Symbol" or "TrueClass".'
        end
        assert_validation(false) do
          error '/', 'Invalid type, got type "FalseClass", expected "String" or "Symbol" or "TrueClass".'
        end
      end

      def test_with_generic_keywords
        schema :object, enum:        [1, 'foo'],
                        title:       'Object schema',
                        description: 'Object schema holding generic keywords',
                        examples:    [
                          'foo'
                        ]

        assert_json({})
      end

      def test_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "strict" must be a "boolean".' do
          schema :object, strict: 'false'
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "strict" must be a "boolean".' do
          schema :object, strict: 123
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "strict" must be a "boolean".' do
          schema :object, strict: [1, 2, 3]
        end

        # rubocop:disable Lint/BooleanSymbol
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "strict" must be a "boolean".' do
          schema :object, strict: :false
        end
        # rubocop:enable Lint/BooleanSymbol
      end
    end
  end
end
