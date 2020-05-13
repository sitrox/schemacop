require 'test_helper'

module Schemacop
  class DefaultsTest < Minitest::Test
    def test_basic
      s = Schema.new :integer, default: 42

      input = nil
      output = s.validate!(input)

      assert_equal(42, output)
    end

    def test_hash
      s = Schema.new do
        opt :foo, :string, default: 'bar'
      end

      input = { foo: nil }
      output = s.validate!(input)
      assert_equal({ foo: 'bar' }, output)
    end

    def test_missing_hash_key
      s = Schema.new do
        opt :foo, :string, default: 'bar'
      end

      input = {}
      output = s.validate!(input)
      assert_equal({ foo: 'bar' }, output)
    end

    def test_entire_hash
      s = Schema.new do
        opt :foo, :hash, default: { name: { first: 'Foo', last: 'Bar' } } do
          req :name do
            req :first
            req :last
          end
        end
      end

      input = {}
      output = s.validate!(input)
      assert_equal({ foo: { name: { first: 'Foo', last: 'Bar' } } }, output)
    end

    def test_entire_array
      s = Schema.new do
        opt :foo, :array, default: [{ bar: 42 }] do
          req :bar
        end
      end

      input = {}
      output = s.validate!(input)
      assert_equal({ foo: [{ bar: 42 }] }, output)
    end

    def test_proc
      s = Schema.new do
        opt :year, :integer, default: ->() { Time.now.year }
      end

      input = {}
      output = s.validate!(input)
      assert_equal({ year: Time.now.year }, output)
    end

    def test_nested_proc
      myproc = proc { 42 }

      s = Schema.new do
        opt :myproc, Proc, default: ->() { myproc }
      end

      input = {}
      output = s.validate!(input)
      assert_equal({ myproc: myproc }, output)
    end

    def test_invalid_default
      s = Schema.new :integer, default: '42'

      input = nil

      assert_verr do
        s.validate!(input)
      end
    end
  end
end
