require 'test_helper'

module Schemacop::V2
  class CustomIfTest < Minitest::Test
    def test_allowed_subset_only
      s = Schema.new do
        type :integer, if: proc { |data| data.odd? }
      end

      assert_nothing_raised { s.validate! 5 }
      assert_verr { s.validate! nil }
      assert_verr { s.validate! 4 }
    end

    def test_if_with_multiple_types
      s = Schema.new do
        type :integer, if: proc { |data| data.odd? }
        type :string
      end

      assert_nothing_raised { s.validate!(5) }
      assert_nothing_raised { s.validate!('abc') }
      assert_verr { s.validate!(4) }
    end

    def test_if_with_string
      s = Schema.new do
        req :foo, :string, if: proc { |data| data.start_with?('a') }, min: 3
        req :foo, :string, min: 5
      end

      assert_nothing_raised { s.validate!(foo: 'abc') }
      assert_nothing_raised { s.validate!(foo: 'bcdef') }
      assert_verr { s.validate!(foo: 'a') }
      assert_verr { s.validate!(foo: 'bcde') }
    end

    def test_if_with_multiple_types_in_field
      s = Schema.new do
        req :foo, :string, if: proc { |data| data.start_with?('a') }
        req :foo, :integer
      end

      assert_nothing_raised { s.validate!(foo: 3) }
      assert_nothing_raised { s.validate!(foo: 'abc') }
      assert_verr { s.validate!(foo: 'bcd') }
      assert_verr { s.validate!(foo: true) }
    end

    def test_if_with_hash_in_array
      s = Schema.new do
        req :user, :array do
          type :hash, if: proc { |data| data[:admin] } do
            req :admin, :boolean
            req :admin_only, :string
          end
          type :hash do
            opt :admin
            req :non_admin_only, :string
          end
        end
      end

      assert_nothing_raised { s.validate!(user: [{ admin: true, admin_only: 'foo' }, { admin: false, non_admin_only: 'foo' }]) }
      assert_nothing_raised { s.validate!(user: [{ admin: true, admin_only: 'foo' }, { non_admin_only: 'foo' }]) }
      assert_verr { s.validate!(user: [{ admin: false, admin_only: 'foo' }]) }
      assert_verr { s.validate!(user: [{ admin: true, non_admin_only: 'foo' }]) }
    end

    def test_if_true_or_false
      s = Schema.new do
        req :foo, :integer, if: proc { true }, min: 5
        req :bar, :integer, if: proc { false }, min: 5
        # TODO: It should work without the following line
        req :bar, :integer
      end

      assert_nothing_raised { s.validate!(foo: 5, bar: 5) }
      assert_nothing_raised { s.validate!(foo: 5, bar: 4) }
      assert_verr { s.validate!(foo: 4, bar: 5) }
      assert_verr { s.validate!(foo: 4, bar: 4) }
    end

    def test_mixed_req_opt
      s = Schema.new do
        req :foo, :integer, if: proc { |data| !data.nil? }
        opt :foo, :integer
      end

      assert_nothing_raised { s.validate!(foo: 4) }
      assert_verr { s.validate!({}) }
      assert_verr { s.validate!('something') }
    end
  end
end
