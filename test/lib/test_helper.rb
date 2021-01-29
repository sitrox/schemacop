require 'simplecov'
SimpleCov.start do
    add_group 'v3', 'lib/schemacop/v3'
    add_group 'v2', 'lib/schemacop/v2'

    # We don't care about the test coverage for the
    # tests themselves
    add_filter 'test'
end

# TODO: Move to more sensible location
def assert_verr(&block)
  assert_raises(Schemacop::V2::Exceptions::ValidationError, &block)
end

# TODO: Move to more sensible location
def assert_nothing_raised(&_block)
  yield
  assert true
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'schemacop'
require 'pry'
require 'colorize'
require 'byebug'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true)]

class SchemacopTest < Minitest::Test
  def assert_is_a(klass, object)
    assert object.is_a?(klass),
           "Expected object with class #{object.class.inspect} to be a #{klass.inspect}."
  end
end

class V2Test < SchemacopTest
  def setup
    Schemacop.default_schema_version = 2
  end
end

class V3Test < SchemacopTest
  class ValidationAssertion
    attr_reader :errors

    def initialize(&block)
      @errors = {}
      instance_exec(&block)
    end

    def error(path, exp)
      @errors[path] ||= []
      @errors[path] << exp
    end
  end

  def setup
    Schemacop.default_schema_version = 3
  end

  # Help test raise errors message
  # https://ruby-doc.org/stdlib-2.1.5/libdoc/test/unit/rdoc/Test/Unit/Assertions.html#method-i-assert_raise
  def assert_raises_with_message(exception, expected, msg = nil, &block)
    case expected
    when String
      assert = :assert_equal
    when Regexp
      assert = :assert_match
    else
      fail TypeError, "Expected #{expected.inspect} to be a kind of String or Regexp, not #{expected.class}"
    end

    ex = assert_raises(exception, *msg, &block)
    msg = message(msg, '') { "Expected Exception(#{exception}) was raised, but the message doesn't match" }

    if assert == :assert_equal
      assert_equal(expected, ex.message, msg)
    else
      msg = message(msg) { "Expected #{mu_pp expected} to match #{mu_pp ex.message}" }
      assert expected =~ ex.message, msg
      block.binding.eval('proc{|_|$~=_}').call($LAST_MATCH_INFO)
    end
    return ex
  end

  def schema(type = :hash, **options, &block)
    @schema = Schemacop::Schema3.new(type, **options, &block)
  end

  def with_context(context, &block)
    Schemacop.with_context(context, &block)
  end

  def assert_validation(data, &block)
    result = @schema.validate(data)

    if block_given?
      assertion = ValidationAssertion.new(&block)

      assert_equal assertion.errors.keys.sort,
                   result.messages_by_path.keys.sort,
                   'Unexpected validation error paths'

      assertion.errors.each do |path, expected_errors|
        actual_errors = result.messages_by_path[path].dup

        assert_equal expected_errors.size,
                     actual_errors.size,
                     "Unexpected number of messages for path #{path}"

        expected_errors.each do |expected_error|
          match = actual_errors.find do |ae|
            if expected_error.is_a?(Regexp)
              expected_error.match?(ae)
            else
              expected_error == ae
            end
          end

          if match
            actual_errors.delete(match)
          else
            assert match,
                   "Did not find error #{expected_error.inspect} in path #{path}, errors: " \
                   + result.messages_by_path[path].inspect
          end
        end
      end
    else
      assert result.errors.empty?,
             "Expected data #{data.inspect} to match schema #{@schema.as_json}, but got errors: #{result.messages}."
    end
  end

  def assert_json(expected_json)
    # TODO: Double "as_json" should not be necessary
    assert_equal expected_json.as_json, @schema.as_json.as_json
  end

  def assert_match_any(array, exp)
    assert array.any? { |element| element.match?(exp) },
           "Expected any of #{array.inspect} to match #{exp}."
  end

  def assert_cast(input_data, expected_data)
    input_data_was = Marshal.load(Marshal.dump(input_data))
    result = @schema.validate(input_data)
    assert_empty result.errors
    assert_equal expected_data, result.data, 'Unexpected result data.'

    if input_data.nil?
      assert_nil input_data_was, 'Expected input_data to stay the same.'
    else
      assert_equal input_data, input_data_was, 'Expected input_data to stay the same.'
    end
  end
end
