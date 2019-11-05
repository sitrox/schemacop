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

      assert_nothing_raised { s.validate!(User.new) }
      assert_verr { s.validate!(SubUser.new) }
      assert_verr { s.validate!(AdminUser.new) }
    end

    # In modern versions of ruby, some classes such as Tempfile are not derived
    # from Object but from BasicObject. Before the time of writing this test,
    # the ObjectValidator only accepted subclasses of Object and classes like
    # Tempfile did not work at all. This test ensures that this is working now.
    def test_basic_object
      refute Tempfile <= Object
      assert Tempfile <= BasicObject

      s = Schema.new do
        type :object
      end

      assert_nothing_raised { s.validate!(Tempfile.new) }

      s = Schema.new do
        req :foo
      end

      assert_nothing_raised { s.validate!(foo: Tempfile.new) }

      s = Schema.new do
        req :foo, Tempfile
      end

      assert_nothing_raised { s.validate!(foo: Tempfile.new) }
      assert_verr { s.validate!(foo: Time.new) }

      s = Schema.new do
        req :foo, :object, classes: Tempfile
      end

      assert_nothing_raised { s.validate!(foo: Tempfile.new) }
    end

    def test_multiple_classes_long
      s = Schema.new do
        type :object, classes: User
        type :object, classes: AdminUser
      end

      assert_nothing_raised { s.validate!(User.new) }
      assert_nothing_raised { s.validate!(AdminUser.new) }
      assert_verr { s.validate!(SubUser.new) }
      assert_verr { s.validate!([User.new, AdminUser.new]) }
    end

    def test_multiple_classes_short
      s = Schema.new do
        type :object, classes: [User, AdminUser]
      end

      assert_nothing_raised { s.validate!(User.new) }
      assert_nothing_raised { s.validate!(AdminUser.new) }
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

      assert_nothing_raised { s.validate!(user: User.new) }
      assert_nothing_raised { s.validate!(user: User.new, multitype: AdminUser.new) }
      assert_nothing_raised { s.validate!(user: User.new, multitype: User.new) }
      assert_verr { s.validate!(user: AdminUser.new) }
      assert_verr { s.validate!(user: User.new, multitype: 12) }
      assert_verr { s.validate!(user: User.new, multitype: self) }
    end

    def test_any
      s = Schema.new do
        type :object
      end

      assert_nothing_raised { s.validate!(User.new) }
      assert_nothing_raised { s.validate!(123) }
      assert_nothing_raised { s.validate!('sali') }
      assert_nothing_raised { s.validate!(self) }
      assert_nothing_raised { s.validate!(self.class) }
      assert_verr { s.validate!(nil) }
    end

    def test_any_in_hash
      s = Schema.new do
        req :fld do
          type :object
        end
      end

      assert_nothing_raised { s.validate!(fld: User.new) }
      assert_nothing_raised { s.validate!(fld: self) }
      assert_verr { s.validate!(fld: nil) }
      assert_verr { s.validate!({}) }
    end

    def test_strict_option
      s = Schema.new do
        req :o_strict do
          type :object, classes: User, strict: true
        end
        opt :o_ns do
          type :object, classes: User, strict: false
        end
      end

      assert_nothing_raised { s.validate!(o_strict: User.new, o_ns: User.new) }
      assert_nothing_raised { s.validate!(o_strict: User.new, o_ns: SubUser.new) }
      assert_nothing_raised { s.validate!(o_strict: User.new) }
      assert_verr { s.validate!(o_strict: SubUser.new) }
      assert_verr { s.validate!(o_strict: User.new, o_ns: AdminUser.new) }
      assert_verr { s.validate!(o_strict: SubUser.new, o_ns: User.new) }
    end
  end
end
