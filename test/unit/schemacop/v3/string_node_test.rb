require 'test_helper'

module Schemacop
  module V3
    class StringNodeTest < V3Test
      def self.invalid_type_error(type)
        "Invalid type, got type \"#{type}\", expected \"string\"."
      end

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
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        schema { str! :name }

        assert_json(type: :object, properties: { name: { type: :string } }, required: %i[name], additionalProperties: false)

        assert_validation name: :foo do
          error '/name', StringNodeTest.invalid_type_error(Symbol)
        end

        assert_validation name: 234 do
          error '/name', StringNodeTest.invalid_type_error(Integer)
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

      def test_pattern_as_string
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

      def test_pattern_as_regexp
        schema :string, pattern: /^a_.*_z$/i

        assert_json(type: :string, pattern: '^(?i)(a_.*_z)$')

        assert_validation 'a__z'
        assert_validation 'a__Z'
        assert_validation 'a_ foo bar _Z'
        assert_validation '' do
          error '/', 'String does not match pattern "^(?i)(a_.*_z)$".'
        end
        assert_validation 'a_ _zfoo' do
          error '/', 'String does not match pattern "^(?i)(a_.*_z)$".'
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

        assert_cast(nil, nil)
        assert_cast('2020-01-13', Date.new(2020, 1, 13))
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

        assert_cast(nil, nil)
        assert_cast('2018-11-13T20:20:39+00:00', DateTime.new(2018, 11, 13, 20, 20, 39))
      end

      def test_format_time
        schema :string, format: :time
        assert_json(type: :string, format: :time)
        assert_cast '20:30:39+00:00', Time.strptime('20:30:39+00:00', '%H:%M:%S%z')

        assert_cast nil, nil
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

        assert_cast(nil, nil)
        assert_cast('john.doe@example.com', 'john.doe@example.com')
      end

      def test_format_mailbox
        schema :string, format: :mailbox

        assert_json(type: :string, format: :mailbox)

        # No angle brackets given
        assert_validation 'john.doe@example.com' do
          error '/', 'String does not match format "mailbox".'
        end

        # Only leading angle bracket given
        assert_validation '<john.doe@example.com' do
          error '/', 'String does not match format "mailbox".'
        end

        # Only trailing angle bracket given
        assert_validation 'john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Both angle brackets given, OK
        assert_validation '<john.doe@example.com>'

        # Both angle brackets given but leading space, not okay
        assert_validation ' <john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Invalid email address given
        assert_validation ' <john>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Invalid email address given
        assert_validation ' <john@>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Invalid email address given
        assert_validation ' <@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Name given but no quotes
        assert_validation 'John Doe <john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Name given but only leading quote
        assert_validation '"John Doe <john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Name given but only trailing quote
        assert_validation 'John Doe" <john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Name given but no space between mail and name
        assert_validation '"John Doe"<john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Too many brackets at start
        assert_validation '"John Doe" <<john.doe@example.com>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Too many brackets at end
        assert_validation '"John Doe" <john.doe@example.com>>' do
          error '/', 'String does not match format "mailbox".'
        end

        # Name with quotes and space before mail, OK
        assert_validation '"John Doe" <john.doe@example.com>'

        # Name with quotes and space before mail with special characters, OK
        assert_validation '"Jöhn Doé-Test" <john.doe@example.com>'

        # Name with quotes and space before mail with angle bracket in name, OK
        assert_validation '"John < Doe" <john.doe@example.com>'

        assert_cast(nil, nil)
        assert_cast('<john.doe@example.com>', '<john.doe@example.com>')
        assert_cast('"John Doe" <john.doe@example.com>', '"John Doe" <john.doe@example.com>')
        assert_cast('"Jöhn Doé-Test" <john.doe@example.com>', '"Jöhn Doé-Test" <john.doe@example.com>')
      end

      def test_format_boolean
        schema :string, format: :boolean

        assert_json(type: :string, format: :boolean)

        assert_cast 'true', true
        assert_cast 'false', false

        assert_cast nil, nil
      end

      def test_format_symbol
        schema :string, format: :symbol

        assert_json(type: :string, format: :symbol)

        assert_validation 'foobar'
        assert_validation ''

        assert_validation 234 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_cast(nil, nil)
        assert_cast('foobar', :foobar)
        assert_cast('039n23$g- sfk3/', :'039n23$g- sfk3/')
      end

      def test_format_integer
        schema :string, format: :integer

        assert_json(type: :string, format: :integer)

        assert_validation '23425'
        assert_validation '-23425'

        assert_validation 12_312 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_validation '24.32' do
          error '/', 'String does not match format "integer".'
        end

        assert_cast(nil, nil)
        assert_cast('2234', 2234)
        assert_cast('-1', -1)
        assert_cast('-0', 0)
      end

      def test_format_integer_list
        schema :string, format: :integer_list

        assert_json(type: :string, format: :'integer-list')

        assert_validation '1,2,3,4'
        assert_validation '1,2,-3,-54'
        assert_validation '2'
        assert_validation '-2'

        assert_validation 234 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_validation 'sd sfdij soidf' do
          error '/', 'String does not match format "integer-list".'
        end

        assert_cast nil,      nil
        assert_cast '1,-2,3', [1, -2, 3]
        assert_cast '1',      [1]
        assert_cast '-1',     [-1]
        assert_cast '08',     [8]
        assert_cast '09',     [9]
        assert_cast '050',    [50]
        assert_cast '01,032', [1, 32]
      end

      def test_format_ipv4
        schema :string, format: :ipv4

        assert_json(type: :string, format: :ipv4)

        assert_validation 234 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_validation 'sd sfdij soidf' do
          error '/', 'String does not match format "ipv4".'
        end

        # Some valid IPv4 addresses
        assert_validation '0.1.2.3'
        assert_validation '110.0.217.94'
        assert_validation '59.1.18.160'
        assert_validation '83.212.124.74'
        assert_validation '208.122.67.117'
        assert_validation '175.186.176.213'

        # Some invalid IPv4 addresses
        assert_validation '256.1.4.2' do
          error '/', 'String does not match format "ipv4".'
        end
        assert_validation '2.4.522.1' do
          error '/', 'String does not match format "ipv4".'
        end
        assert_validation '1.1.1' do
          error '/', 'String does not match format "ipv4".'
        end
        assert_validation '1' do
          error '/', 'String does not match format "ipv4".'
        end

        # CIDR addresses are not allowed
        assert_validation '247.182.236.127/24' do
          error '/', 'String does not match format "ipv4".'
        end

        # And IPv6 isn't allowed as well
        assert_validation 'd91c:af3e:72f1:f5c3::::ad81' do
          error '/', 'String does not match format "ipv4".'
        end
      end

      def test_format_ipv4_cidr
        schema :string, format: :'ipv4-cidr'

        assert_json(type: :string, format: :'ipv4-cidr')

        assert_validation 234 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_validation 'sd sfdij soidf' do
          error '/', 'String does not match format "ipv4-cidr".'
        end

        # Some valid IPv4 CIDR addresses
        assert_validation '0.1.2.3/23'
        assert_validation '110.0.217.94/1'
        assert_validation '59.1.18.160/32'
        assert_validation '83.212.124.74/24'
        assert_validation '208.122.67.117/10'
        assert_validation '175.186.176.213/8'

        # Validate all subnets
        (0..32).each do |subnet|
          assert_validation "123.4.53.12/#{subnet}"
        end

        # Some invalid IPv4 CIDR addresses
        assert_validation '256.1.4.2/24' do
          error '/', 'String does not match format "ipv4-cidr".'
        end
        assert_validation '2.4.522.1/32' do
          error '/', 'String does not match format "ipv4-cidr".'
        end
        assert_validation '1.1.1/21' do
          error '/', 'String does not match format "ipv4-cidr".'
        end
        assert_validation '1/4' do
          error '/', 'String does not match format "ipv4-cidr".'
        end
        assert_validation '0.1.2.3/33' do
          error '/', 'String does not match format "ipv4-cidr".'
        end
        assert_validation '0.1.2.3/123' do
          error '/', 'String does not match format "ipv4-cidr".'
        end

        # Normal IPv4 addresses are not allowed
        assert_validation '247.182.236.127' do
          error '/', 'String does not match format "ipv4-cidr".'
        end

        # And IPv6 isn't allowed as well
        assert_validation 'd91c:af3e:72f1:f5c3::::ad81' do
          error '/', 'String does not match format "ipv4-cidr".'
        end
      end

      def test_format_ipv6
        schema :string, format: :ipv6

        assert_json(type: :string, format: :ipv6)

        assert_validation 234 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_validation 'sd sfdij soidf' do
          error '/', 'String does not match format "ipv6".'
        end

        # Some valid IPv6 addresses
        assert_validation '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
        assert_validation '::1'
        assert_validation '2001:db8::ff00:42:8329'

        # Some invalid IPv6 addresses
        assert_validation '2001:db8:85a3:0000:0000:8a2e:0370:7334:1234' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '2001:db8:85a3::8a2e::7334' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '2001:db8:85a3::g123:4567' do
          error '/', 'String does not match format "ipv6".'
        end

        # CIDR addresses are not allowed
        assert_validation '247.182.236.127/24' do
          error '/', 'String does not match format "ipv6".'
        end

        # And IPv4 isn't allowed as well
        assert_validation '0.1.2.3' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '110.0.217.94' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '59.1.18.160' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '83.212.124.74' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '208.122.67.117' do
          error '/', 'String does not match format "ipv6".'
        end
        assert_validation '175.186.176.213' do
          error '/', 'String does not match format "ipv6".'
        end
      end

      def test_format_custom
        Schemacop.register_string_formatter(
          :integer_tuple_list,
          pattern: /^(-?[0-9]+):(-?[0-9]+)(,(-?[0-9]+):(-?[0-9]+))*$/,
          handler: proc do |value|
            value.split(',').map { |t| t.split(':').map(&:to_i) }
          end
        )

        schema :string, format: :integer_tuple_list

        assert_json(type: :string, format: :'integer-tuple-list')

        assert_validation '1:5,4:2,-4:4,4:-1,0:0'
        assert_validation '-1:5'

        assert_validation 234 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_validation 'sd sfdij soidf' do
          error '/', 'String does not match format "integer-tuple-list".'
        end

        assert_cast nil, nil
        assert_cast '1:2,3:4,5:-6', [[1, 2], [3, 4], [5, -6]]
      end

      def test_enum
        schema :string, enum: ['foo', 'some string', 'some other string', 42]

        assert_json(type: :string, enum: ['foo', 'some string', 'some other string', 42])

        assert_validation 'foo'
        assert_validation 'some string'
        assert_validation 'some other string'

        assert_validation 'fooo' do
          error '/', 'Value not included in enum ["foo", "some string", "some other string", 42].'
        end

        assert_validation 'other value' do
          error '/', 'Value not included in enum ["foo", "some string", "some other string", 42].'
        end

        # Integer value 42 is in the enum of allowed values, but it's not a string,
        # so the validation still fails
        assert_validation 42 do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end
      end

      def test_date_time_casting
        schema :string, format: :date_time
        assert_json(type: :string, format: :'date-time')
        assert_cast '2018-11-13T20:20:39+00:00', DateTime.new(2018, 11, 13, 20, 20, 39)
        assert_cast '2018-11-13T20:20:39Z', DateTime.new(2018, 11, 13, 20, 20, 39)
        assert_cast '2018-11-13T20:20:39+01:00', DateTime.new(2018, 11, 13, 20, 20, 39, '+1')

        assert_cast nil, nil
      end

      def test_email_casting
        schema :string, format: :email
        assert_json(type: :string, format: :email)
        assert_cast 'support@example.com', 'support@example.com'

        assert_cast nil, nil
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
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_cast('Foo', 'Foo')
        assert_cast(nil, 'Hello')
      end

      def test_default_casting
        schema :string, format: :integer, default: '42'

        assert_json(
          type:    :string,
          format:  :integer,
          default: '42'
        )

        assert_validation(nil)
        assert_validation('123')
        assert_validation(5) do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end

        assert_cast('123', 123)
        assert_cast(nil, 42)
      end

      # Helper function that checks for all the options if the option is
      # an integer or something else, in which case it needs to raise
      def validate_self_should_error(value_to_check)
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "min_length" must be an "integer"' do
          schema :string, min_length: value_to_check
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "max_length" must be an "integer"' do
          schema :string, max_length: value_to_check
        end
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
                                   'Option "pattern" must be a string or Regexp.' do
          schema :string, pattern: 42
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "pattern" can\'t be parsed: end pattern ' \
                                   'with unmatched parenthesis: /(abcde/.' do
          schema :string, pattern: '(abcde'
        end

        validate_self_should_error(1.0)
        validate_self_should_error(4r)
        validate_self_should_error(true)
        validate_self_should_error(false)
        validate_self_should_error(Object.new)
        validate_self_should_error((4 + 6i))
        validate_self_should_error('13')
        validate_self_should_error('Lorem ipsum')
      end

      def test_enum_schema
        schema :string, enum: [1, 2, 'foo', :bar, { qux: 42 }]

        assert_json({
                      type: :string,
                      enum: [1, 2, 'foo', :bar, { qux: 42 }]
                    })

        assert_validation(nil)
        assert_validation('foo')

        # Even we put those types in the enum, they need to fail the validations,
        # as they are not strings
        assert_validation(1) do
          error '/', StringNodeTest.invalid_type_error(Integer)
        end
        assert_validation(:bar) do
          error '/', StringNodeTest.invalid_type_error(Symbol)
        end
        assert_validation({ qux: 42 }) do
          error '/', StringNodeTest.invalid_type_error(Hash)
        end

        # These need to fail validation, as they are not in the enum list
        assert_validation('bar') do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
          end
        end
        assert_validation('Lorem ipsum') do
          if new_hash_inspect_format?
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {qux: 42}].'
          else
            error '/', 'Value not included in enum [1, 2, "foo", :bar, {:qux=>42}].'
          end
        end
      end

      def test_with_generic_keywords
        schema :string, enum:        [1, 'foo'],
                        title:       'String schema',
                        description: 'String schema holding generic keywords',
                        examples:    [
                          'foo'
                        ]

        assert_json({
                      type:        :string,
                      enum:        [1, 'foo'],
                      title:       'String schema',
                      description: 'String schema holding generic keywords',
                      examples:    [
                        'foo'
                      ]
                    })
      end

      def test_cast_empty_or_whitespace_string
        schema :string

        assert_cast(nil, nil)
        assert_cast('', '')
        assert_cast('    ', '    ')
        assert_cast("\n", "\n")
        assert_cast("\t", "\t")
      end

      def test_cast_empty_or_whitespace_string_required
        schema :string, required: true

        assert_validation(nil) do
          error '/', 'Value must be given.'
        end

        assert_cast('', '')
        assert_cast('    ', '    ')
        assert_cast("\n", "\n")
        assert_cast("\t", "\t")
      end

      def test_encoding_single
        schema :string, encoding: 'UTF-8'

        assert_validation 'Hello World'
        assert_validation ''

        assert_validation 'Hello World'.encode('ASCII') do
          error '/', 'String has encoding "US-ASCII" but must be "UTF-8".'
        end
      end

      def test_encoding_multiple
        schema :string, encoding: %w[UTF-8 US-ASCII]

        assert_validation 'Hello World'
        assert_validation 'Hello World'.encode('ASCII')

        assert_validation 'Hello World'.encode('ISO-8859-1') do
          error '/', 'String has encoding "ISO-8859-1" but must be "UTF-8" or "US-ASCII".'
        end
      end

      def test_encoding_with_nil
        schema :string, encoding: 'UTF-8'

        assert_validation nil
      end

      def test_encoding_invalid_bytes
        schema :string, encoding: 'UTF-8'

        invalid_string = "abc\x80def".force_encoding('UTF-8')
        assert_validation invalid_string do
          error '/', 'String has invalid "UTF-8" encoding.'
        end
      end

      def test_encoding_invalid_bytes_without_specific_encoding
        schema :string

        invalid_string = "abc\x80def".force_encoding('UTF-8')
        assert_validation invalid_string do
          error '/', 'String has invalid "UTF-8" encoding.'
        end
      end

      def test_encoding_validate_self
        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "encoding" must be a string or an array of strings.' do
          schema :string, encoding: 123
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "encoding" must be a string or an array of strings.' do
          schema :string, encoding: [123]
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "encoding" contains unknown encoding "UNKNOWN-FOO".' do
          schema :string, encoding: 'UNKNOWN-FOO'
        end

        assert_raises_with_message Exceptions::InvalidSchemaError,
                                   'Option "encoding" contains unknown encoding "UNKNOWN-FOO".' do
          schema :string, encoding: ['UTF-8', 'UNKNOWN-FOO']
        end
      end

      def test_empty_or_whitespace_string_blank_not_allowed
        schema :string, allow_blank: false

        assert_validation(nil) do
          error '/', 'String is blank but must not be blank!'
        end

        assert_validation('') do
          error '/', 'String is blank but must not be blank!'
        end

        assert_validation('   ') do
          error '/', 'String is blank but must not be blank!'
        end

        assert_validation("\n") do
          error '/', 'String is blank but must not be blank!'
        end

        assert_validation("\t") do
          error '/', 'String is blank but must not be blank!'
        end
      end
    end
  end
end
