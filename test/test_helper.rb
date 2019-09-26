require 'minitest/autorun'
require 'schemacop'
require 'pry'
require 'colorize'

def assert_verr(&_block)
  assert_raises(Schemacop::Exceptions::ValidationError) { yield }
end

def assert_nothing_raised(&_block)
  yield
  assert true
end
