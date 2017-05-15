require 'test_helper'

module Schemacop
  class ValidatorObjectTest < Minitest::Test
    # Classes used in the tests below
    class User; end
    class AdminUser; end
    class SubUser < User; end

    def test_basic
      s = Schema.new do
        type :object, classes: User
      end

      assert_nil s.validate!(User.new)
      assert_verr { s.validate!(SubUser.new) }
      assert_verr { s.validate!(AdminUser.new) }
    end

    def test_multiple_classes_long
      s = Schema.new do
        type :object, classes: User
        type :object, classes: AdminUser
      end

      assert_nil s.validate!(User.new)
      assert_nil s.validate!(AdminUser.new)
      assert_verr { s.validate!(SubUser.new) }
      assert_verr { s.validate!([User.new, AdminUser.new]) }
    end

    def test_multiple_classes_short
      s = Schema.new do
        type :object, classes: [User, AdminUser]
      end

      assert_nil s.validate!(User.new)
      assert_nil s.validate!(AdminUser.new)
      assert_verr { s.validate!(SubUser.new) }
      assert_verr { s.validate!([User.new, AdminUser.new]) }
    end

    def test_hash_of_objects
      s = Schema.new do
        req :user do
          type :object, classes: User
        end
        opt :multitype do
          type :object, classes: [User, AdminUser]
        end
      end

      assert_nil s.validate!(user: User.new)
      assert_nil s.validate!(user: User.new, multitype: AdminUser.new)
      assert_nil s.validate!(user: User.new, multitype: User.new)
      assert_verr { s.validate!(user: AdminUser.new) }
      assert_verr { s.validate!(user: User.new, multitype: 12) }
      assert_verr { s.validate!(user: User.new, multitype: self) }
    end

    def test_any
      s = Schema.new do
        type :object
      end

      assert_nil s.validate!(User.new)
      assert_nil s.validate!(123)
      assert_nil s.validate!('sali')
      assert_nil s.validate!(self)
      assert_nil s.validate!(self.class)
      assert_verr { s.validate!(nil) }
    end

    def test_any_in_hash
      s = Schema.new do
        req :fld do
          type :object
        end
      end

      assert_nil s.validate!(fld: User.new)
      assert_nil s.validate!(fld: self)
      assert_verr { s.validate!(fld: nil) }
      assert_verr { s.validate!({}) }
    end
  end
end
