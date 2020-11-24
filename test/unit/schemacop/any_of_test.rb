require 'test_helper'

module Schemacop
  class AnyOfTest < SchemacopTest
    def test_optional
      schema :any_of do
        str
        int
      end

      assert_validation(nil)
      assert_validation('string')
      assert_validation(42)
      assert_validation(42.1) do
        error '/', 'Does not match any anyOf condition.'
      end
      assert_validation({}) do
        error '/', 'Does not match any anyOf condition.'
      end
    end

    def test_required
      schema :any_of, required: true do
        str
        int
      end

      assert_validation('string')
      assert_validation(42)

      # TODO: Fix this bug in validation
      # assert_validation(nil) do
      #   error '/', 'Does not match any anyOf condition.'
      # end

      assert_validation(42.1) do
        error '/', 'Does not match any anyOf condition.'
      end
      assert_validation({}) do
        error '/', 'Does not match any anyOf condition.'
      end
    end

    def test_nested
      schema :any_of do
        obj do
          any_of! :foo do
            int
            str
          end
        end
        int
      end

      assert_validation(42)
      assert_validation(foo: 42)
      assert_validation(foo: 'str')
      assert_validation('string') do
        error '/', 'Does not match any anyOf condition.'
      end
      assert_validation(bar: :baz) do
        error '/', 'Does not match any anyOf condition.'
      end
      assert_validation(foo: :bar) do
        error '/', 'Does not match any anyOf condition.'
      end
    end

    def test_all_types
      schema :any_of do
        all_of do
          obj { str! :foo }
        end
        any_of
        ary
        boo
        int
        num
        obj { int! :bar }
        one_of do
          obj { str! :a, pattern: '^a' }
          obj { str! :a, pattern: 'z$' }
        end
        ref :MyDate
        str max_length: 2
      end

      context = Context.new
      context.schema :MyDate, :string, format: :date

      Schemacop.with_context context do
        assert_validation(foo: 'str')
        assert_validation([1, 2, 3])
        assert_validation(true)
        assert_validation(false)
        assert_validation(42)
        assert_validation(42.2)
        assert_validation(bar: 42)
        assert_validation(a: 'a hello')
        assert_validation(a: 'hello z')
        assert_validation('1990-01-13')
        assert_validation('12')

        assert_validation('1990-01-13 12') do
          error '/', 'Does not match any anyOf condition.'
        end
        assert_validation(a: 'a hello z') do
          error '/', 'Does not match any anyOf condition.'
        end
        assert_validation(Object.new) do
          error '/', 'Does not match any anyOf condition.'
        end
      end
    end

    def test_casting
      schema do
        any_of! :created_at do
          str format: :date
          str format: :date_time
        end
      end

      assert_validation(created_at: '2020-01-01')
      assert_validation(created_at: '2020-01-01T17:38:20')

      assert_cast(
        { created_at: '2020-01-01' },
        created_at: Date.new(2020, 1, 1)
      )
      assert_cast(
        { created_at: '2020-01-01T17:38:20' },
        created_at: DateTime.new(2020, 1, 1, 17, 38, 20)
      )
    end

    def test_defaults
      schema do
        any_of! :foo do
          obj { str? :bar }
          obj { str? :baz, default: 'Baz' }
        end
      end

      assert_validation(foo: { bar: 'Bar' })
      assert_validation(foo: { baz: 'Baz' })

      assert_validation(foo: { xyz: 'Baz' }) do
        error '/foo', 'Does not match any anyOf condition.'
      end

      assert_cast(
        { foo: { bar: nil } },
        foo: { bar: nil }
      )

      assert_cast(
        { foo: { baz: nil } },
        foo: { baz: 'Baz' }
      )

      schema do
        any_of! :foo do
          obj { str? :bar, format: :date }
          obj { str? :bar, default: 'Baz', format: :date_time }
        end
      end

      assert_cast(
        { foo: { bar: '1990-01-13' } },
        foo: { bar: Date.new(1990, 1, 13) }
      )

      assert_cast(
        { foo: { bar: '1990-01-13T10:00:00Z' } },
        foo: { bar: DateTime.new(1990, 1, 13, 10, 0, 0) }
      )
    end
  end
end
