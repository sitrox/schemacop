require 'test_helper'

module Schemacop
  class EmptyTest < Minitest::Test
    def test_empty_hash
      schema = Schema.new do
        type Hash
      end

      assert_nothing_raised { schema.validate!({}) }
      assert_verr { schema.validate!(foo: :bar) }
    end
  end
end
