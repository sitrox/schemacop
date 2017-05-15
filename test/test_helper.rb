require 'minitest/autorun'
require 'schemacop'

def assert_verr(&_block)
  assert_raises(Schemacop::Exceptions::ValidationError) { yield }
end
