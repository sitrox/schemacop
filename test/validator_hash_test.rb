require 'test_helper'

module Schemacop
  class ValidatorHashTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :hash do
          req :one do
            type :integer
          end
          req :two do
            type :boolean
          end
        end
      end
      assert_nothing_raised { s.validate!(one: 3, two: true) }
      assert_verr { s.validate!(one: 3) }
      assert_verr { s.validate!(two: true) }
      assert_verr { s.validate!({}) }
      assert_verr { s.validate!(one: 3, two: true, three: 3) }
      assert_verr { s.validate!(one: 3, three: true) }
    end

    def test_nested
      s = Schema.new do
        type :hash do
          req :h do
            type :hash do
              req :i do
                type :integer
              end
            end
          end
        end
      end
      s.validate(h: { i: 3 })
      assert_verr { s.validate!(h: { i: true }) }
      assert_verr { s.validate!(h: {}) }
      assert_verr { s.validate!({}) }
      assert_verr { s.validate!(g: { i: 3 }) }
      assert_verr { s.validate!(h: { j: 3 }) }
    end

    def test_req_opt
      s = Schema.new do
        type :hash do
          req :r do
            type :boolean
          end
          req? :r_nil do
            type :boolean
          end
          opt :o do
            type :boolean
          end
          opt! :o_nonnil do
            type :boolean
          end
        end
      end

      assert_nothing_raised { s.validate!(r: true, r_nil: false) }
      assert_nothing_raised { s.validate!(r: true, r_nil: nil) }
      assert_nothing_raised { s.validate!(r: true, r_nil: false, o: false) }
      assert_nothing_raised { s.validate!(r: true, r_nil: false, o: nil) }
      assert_verr { s.validate!(r: true, r_nil: false, o_nonnil: nil) }
      assert_verr { s.validate!(o: true) }
      assert_verr { s.validate!(r: nil, r_nil: false, o: true) }
    end
  end
end
