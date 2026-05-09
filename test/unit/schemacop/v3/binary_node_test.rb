require 'test_helper'

module Schemacop
  module V3
    class BinaryNodeTest < V3Test
      def test_basic
        schema :binary

        assert_validation nil
        assert_validation Tempfile.new('test')
        assert_validation 'binary string data'

        assert_json(type: :string, format: :binary)
      end

      def test_required
        schema :binary, required: true

        assert_validation Tempfile.new('test')

        assert_validation nil do
          error '/', 'Value must be given.'
        end

        assert_json(type: :string, format: :binary)
      end

      def test_type
        schema :binary

        assert_validation 'foo'
        assert_validation Tempfile.new('test')

        assert_validation 42 do
          error '/', 'Invalid type, got type "Integer", expected "String" or "Tempfile".'
        end

        assert_validation true do
          error '/', 'Invalid type, got type "TrueClass", expected "String" or "Tempfile".'
        end

        assert_validation :foo do
          error '/', 'Invalid type, got type "Symbol", expected "String" or "Tempfile".'
        end
      end

      def test_hash
        schema do
          bin! :attachment
        end

        assert_json(
          type:                 :object,
          properties:           {
            attachment: { type: :string, format: :binary }
          },
          required:             %i[attachment],
          additionalProperties: false
        )

        assert_validation attachment: Tempfile.new('test')
        assert_validation attachment: 'binary data'

        assert_validation({}) do
          error '/attachment', 'Value must be given.'
        end

        assert_validation(attachment: 42) do
          error '/attachment', 'Invalid type, got type "Integer", expected "String" or "Tempfile".'
        end
      end

      def test_hash_optional
        schema do
          bin? :attachment
        end

        assert_json(
          type:                 :object,
          properties:           {
            attachment: { type: :string, format: :binary }
          },
          additionalProperties: false
        )

        assert_validation attachment: Tempfile.new('test')
        assert_validation({})
        assert_validation attachment: nil
      end

      def test_array
        schema(:array) do
          list :binary
        end

        assert_validation [Tempfile.new('a'), Tempfile.new('b')]
        assert_json(type: :array, items: { type: :string, format: :binary })
      end

      def test_with_custom_classes
        schema :binary, classes: [String, Integer]

        assert_validation 'hello'
        assert_validation 42
        assert_validation nil

        assert_validation :foo do
          error '/', 'Invalid type, got type "Symbol", expected "Integer" or "String".'
        end
      end

      def test_with_single_custom_class
        schema :binary, classes: [Tempfile]

        assert_validation Tempfile.new('test')

        assert_validation 'hello' do
          error '/', 'Invalid type, got type "String", expected "Tempfile".'
        end
      end

      def test_custom_classes_uses_is_a
        schema :binary, classes: [Numeric]

        assert_validation 42
        assert_validation 3.14
        assert_validation BigDecimal('1.5')

        assert_validation 'hello' do
          error '/', 'Invalid type, got type "String", expected "Numeric".'
        end
      end

      def test_default
        schema :binary, default: Tempfile.new('default')

        assert_validation nil
        assert_validation Tempfile.new('other')
      end

      def test_enum
        tempfile_a = Tempfile.new('a')
        tempfile_b = Tempfile.new('b')
        tempfile_c = Tempfile.new('c')

        schema :binary, enum: [tempfile_a, tempfile_b]

        assert_validation nil
        assert_validation tempfile_a
        assert_validation tempfile_b

        assert_validation tempfile_c do
          error '/', /Value not included in enum/
        end
      end

      def test_with_generic_keywords
        schema :binary, title:       'Binary schema',
                        description: 'Binary schema holding generic keywords',
                        examples:    [
                          'binary data'
                        ]

        assert_json(
          type:        :string,
          format:      :binary,
          title:       'Binary schema',
          description: 'Binary schema holding generic keywords',
          examples:    [
            'binary data'
          ]
        )
      end

      def test_validate_self_classes_not_array
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "classes" must be an array of classes.' do
          schema :binary, classes: 'String'
        end
      end

      def test_validate_self_classes_empty
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "classes" must not be empty.' do
          schema :binary, classes: []
        end
      end

      def test_validate_self_classes_not_classes
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "classes" must contain classes, got "String".' do
          schema :binary, classes: ['String']
        end
      end

      def test_validate_self_classes_mixed
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "classes" must contain classes, got :symbol.' do
          schema :binary, classes: [String, :symbol]
        end
      end

      def test_validate_self_classes_with_module
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "classes" must contain classes, got Comparable.' do
          schema :binary, classes: [Comparable]
        end
      end

      def test_cast
        tempfile = Tempfile.new('test')
        schema :binary

        result = @schema.validate(tempfile)
        assert_empty result.errors
        assert_equal tempfile, result.data

        result = @schema.validate(nil)
        assert_empty result.errors
        assert_nil result.data
      end

      def test_cast_default
        default_file = Tempfile.new('default')
        schema :binary, default: default_file

        result = @schema.validate(nil)
        assert_empty result.errors
        assert_equal default_file, result.data
      end

      def test_cast_in_hash
        schema do
          bin? :attachment
        end

        tempfile = Tempfile.new('test')
        result = @schema.validate(attachment: tempfile)
        assert_empty result.errors
        assert_equal({ 'attachment' => tempfile }, result.data)

        result = @schema.validate({})
        assert_empty result.errors
        assert_equal({}, result.data)
      end

      def test_default_classes_include_string
        schema :binary

        assert_validation 'a plain string'
      end

      def test_as_json
        schema :binary

        assert_json(type: :string, format: :binary)
      end

      def test_swagger_json
        schema :binary

        assert_swagger_json(type: :string, format: :binary)
      end
    end
  end
end
