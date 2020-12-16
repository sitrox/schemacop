require 'test_helper'

module Schemacop
  module V3
    class AllOfNodeTest < V3Test
      def test_optional
        schema :all_of do
          str min_length: 2
          str max_length: 4
        end

        assert_validation(nil)
        assert_validation('12')
        assert_validation('1234')
        assert_validation('1234')
        assert_validation('1') do
          error '/', 'Does not match all allOf conditions.'
        end
        assert_validation('12345') do
          error '/', 'Does not match all allOf conditions.'
        end
      end

      def test_required
        schema :all_of, required: true do
          int minimum: 2
          int maximum: 4
        end

        assert_validation(2)
        assert_validation(3)
        assert_validation(4)

        assert_validation(5) do
          error '/', 'Does not match all allOf conditions.'
        end
        assert_validation(1) do
          error '/', 'Does not match all allOf conditions.'
        end
        assert_validation({}) do
          error '/', 'Does not match all allOf conditions.'
        end
        assert_validation(42) do
          error '/', 'Does not match all allOf conditions.'
        end
      end

      def test_nested
        schema :all_of do
          hsh additional_properties: true do
            all_of! :foo do
              int minimum: 2
              int maximum: 4
            end
          end
          hsh additional_properties: true do
            any_of! :bar do
              int minimum: 6
              int maximum: 8
            end
          end
        end

        assert_validation(foo: 2, bar: 7)
        assert_validation(foo: 5, bar: 7) do
          error '/', 'Does not match all allOf conditions.'
        end
        assert_validation(foo: 5) do
          error '/', 'Does not match all allOf conditions.'
        end
      end

      def test_casting
        schema :all_of do
          hsh additional_properties: true do
            str! :foo, format: :integer
          end
          hsh additional_properties: true do
            str! :bar, format: :date
          end
        end

        assert_validation(foo: '42', bar: '2020-01-15')

        # TODO: Enable again once this works
        # assert_cast(
        #   { foo: '42', bar: '2020-01-15' },
        #   foo: 42,
        #   bar: Date.new(2020, 1, 15)
        # )
      end

      # TODO: Write this test once it works
      # def test_defaults
      # end
    end
  end
end