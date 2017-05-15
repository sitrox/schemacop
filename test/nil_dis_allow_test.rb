require 'test_helper'

# Note: A test for req and opt is part of validator_hash_test.rb

module Schemacop
  class NilDisAllowTest < Minitest::Test
    def test_req
      s = Schema.new do
        req? :o do
          type :boolean
        end

        req :r do
          type :boolean
        end
      end
      assert_nil s.validate!(o: nil, r: false)
      assert_nil s.validate!(o: false, r: false)
      assert_verr { s.validate!(o: true, r: nil) }
      assert_verr { s.validate!(o: nil, r: nil) }
      assert_verr { s.validate!(r: true) }
    end

    def test_opt
      s = Schema.new do
        opt :o do
          type :boolean
        end
        opt! :r do
          type :boolean
        end
      end
      assert_nil s.validate!(o: nil, r: false)
      assert_nil s.validate!(o: false, r: false)
      assert_nil s.validate!(r: true)
      assert_nil s.validate!({})
      assert_verr { s.validate!(o: true, r: nil) }
      assert_verr { s.validate!(o: nil, r: nil) }
    end
  end
end
