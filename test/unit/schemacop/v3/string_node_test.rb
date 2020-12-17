require 'test_helper'

module Schemacop
  module V3
    class StringNodeTest < V3Test
      EXP_INVALID_TYPE = 'Invalid type, expected "string".'.freeze

      def test_basic
        schema :string
        assert_validation 'Hello World'
        assert_validation ''
        assert_json(type: :string)
      end

      def test_required
        schema :string, required: true
        assert_validation 'Hello World'
        assert_validation ''
        assert_validation nil do
          error '/', 'Value must be given.'
        end
      end

      def test_hash
        schema { str! :name }
        assert_validation name: 'Hello World'
        assert_json(type: :object, properties: { name: { type: :string } }, required: %i[name], additionalProperties: false)
      end

      def test_type
        schema :string

        assert_json(type: :string)

        assert_validation 42 do
          error '/', EXP_INVALID_TYPE
        end

        schema { str! :name }

        assert_json(type: :object, properties: { name: { type: :string } }, required: %i[name], additionalProperties: false)

        assert_validation name: :foo do
          error '/name', EXP_INVALID_TYPE
        end

        assert_validation name: 234 do
          error '/name', EXP_INVALID_TYPE
        end
      end

      def test_min_length
        schema :string, min_length: 5

        assert_json(type: :string, minLength: 5)

        assert_validation '12345'
        assert_validation '12345678'

        assert_validation '1234' do
          error '/', 'String is 4 characters long but must be at least 5.'
        end

        assert_validation '' do
          error '/', 'String is 0 characters long but must be at least 5.'
        end
      end

      def test_max_length
        schema :string, max_length: 5

        assert_json(type: :string, maxLength: 5)

        assert_validation ''
        assert_validation '12345'
        assert_validation '1234'

        assert_validation '123456' do
          error '/', 'String is 6 characters long but must be at most 5.'
        end
      end

      def test_pattern
        schema :string, pattern: '^a_.*_z$'

        assert_json(type: :string, pattern: '^a_.*_z$')

        assert_validation 'a__z'
        assert_validation 'a_ foo bar _z'
        assert_validation '' do
          error '/', 'String does not match pattern "^a_.*_z$".'
        end
        assert_validation 'a_ _zfoo' do
          error '/', 'String does not match pattern "^a_.*_z$".'
        end
      end

      def test_format_date
        schema :string, format: :date

        assert_json(type: :string, format: :date)

        assert_validation '2020-01-13'
        assert_validation '2020-02-29'
        assert_validation '2021-02-29' # Leap years are not validated

        assert_validation '2020-13-29' do
          error '/', 'String does not match format "date".'
        end

        assert_validation 'foo 2020-01-29 bar' do
          error '/', 'String does not match format "date".'
        end
      end

      def test_format_date_time
        schema :string, format: :date_time

        assert_json(type: :string, format: :'date-time')

        assert_validation '2018-11-13T20:20:39+00:00'
        assert_validation '2018-11-13T20:20:39Z'

        assert_validation '2020-13-29' do
          error '/', 'String does not match format "date-time".'
        end

        assert_validation '2018-13-13T20:20:39+00:00' do
          error '/', 'String does not match format "date-time".'
        end

        assert_validation '2018-11-13T20:20:39Y' do
          error '/', 'String does not match format "date-time".'
        end
      end

      def test_format_email
        schema :string, format: :email

        assert_json(type: :string, format: :email)

        assert_validation 'john.doe@example.com'
        assert_validation 'john.doe+foo-bar_baz@example.com'
        assert_validation 'JOHN.DOE+FOO-BAR_BAZ@EXAMPLE.COM'

        assert_validation 'someemail' do
          error '/', 'String does not match format "email".'
        end

        assert_validation 'john doe@example.com' do
          error '/', 'String does not match format "email".'
        end

        assert_validation '@john@example.com' do
          error '/', 'String does not match format "email".'
        end
      end

      # TODO: Should enums be allowed for any type, not just string? Check doc.
      def test_enum
        schema :string, enum: ['foo', 'some string', 'some other string']

        assert_json(type: :string, enum: ['foo', 'some string', 'some other string'])

        assert_validation 'foo'
        assert_validation 'some string'
        assert_validation 'some other string'

        assert_validation 'fooo' do
          error '/', 'Value not included in enum ["foo", "some string", "some other string"].'
        end

        assert_validation 'other value' do
          error '/', 'Value not included in enum ["foo", "some string", "some other string"].'
        end
      end

      def test_boolean_casting
        schema :string, format: :boolean

        assert_json(type: :string, format: :boolean)

        assert_cast 'true', true
        assert_cast 'false', false
      end

      def test_time_casting
        schema :string, format: :time
        assert_json(type: :string, format: :time)
        assert_cast '20:30:39+00:00', Time.strptime('20:30:39+00:00', '%H:%M:%S%z')
      end

      def test_date_casting
        schema :string, format: :date
        assert_json(type: :string, format: :date)
        assert_cast '2018-11-13', Date.new(2018, 11, 13)
      end

      def test_date_time_casting
        schema :string, format: :date_time
        assert_json(type: :string, format: :'date-time')
        assert_cast '2018-11-13T20:20:39+00:00', DateTime.new(2018, 11, 13, 20, 20, 39)
        assert_cast '2018-11-13T20:20:39Z', DateTime.new(2018, 11, 13, 20, 20, 39)
        assert_cast '2018-11-13T20:20:39+01:00', DateTime.new(2018, 11, 13, 20, 20, 39, '+1')
      end

      def test_email_casting
        schema :string, format: :email
        assert_json(type: :string, format: :email)
        assert_cast 'support@example.com', 'support@example.com'
      end

      def test_default
        schema :string, default: 'Hello'

        assert_json(
          type:    :string,
          default: 'Hello'
        )

        assert_validation(nil)
        assert_validation('Foo')
        assert_validation(5) do
          error '/', 'Invalid type, expected "string".'
        end

        assert_cast('Foo', 'Foo')
        assert_cast(nil, 'Hello')
      end

      def test_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Format "not-existing" is not supported.' do
          schema :string, format: :not_existing
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "min_length" can\'t be greater than "max_length".' do
          schema :string, min_length: 5, max_length: 4
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "pattern" must be a string.' do
          schema :string, pattern: //
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "pattern" can\'t be parsed: end pattern '\
                                   'with unmatched parenthesis: /(abcde/.' do
          schema :string, pattern: '(abcde'
        end
      end
    end
  end
end
