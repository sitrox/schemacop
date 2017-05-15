require 'test_helper'

module Schemacop
  class ValidatorArrayTest < Minitest::Test
    def test_basic
      s = Schema.new do
        type :array do
          type :integer
        end
      end
      assert_nil s.validate!([])
      assert_nil s.validate!([0])
      assert_nil s.validate!([0, 1])
      assert_verr { s.validate!(['string']) }
    end

    def test_option_min
      s = Schema.new do
        type :array, min: 2
      end

      assert_nil s.validate!([0, 1])
      assert_nil s.validate!([0, 1, 2])
      assert_verr { s.validate!([]) }
      assert_verr { s.validate!([0]) }
    end

    def test_option_max
      s = Schema.new do
        type :array, max: 2
      end

      assert_nil s.validate!([])
      assert_nil s.validate!([0])
      assert_nil s.validate!([0, 1])
      assert_verr { s.validate!([0, 1, 2]) }
    end

    def test_options_min_max
      s = Schema.new do
        type :array, min: 2, max: 3 do
          type :integer
        end
      end

      assert_nil s.validate!([1, 2])
      assert_nil s.validate!([1, 2, 3])
      assert_verr { s.validate!([]) }
      assert_verr { s.validate!([1]) }
      assert_verr { s.validate!([1, 2, 3, 4]) }
    end

    def test_nil
      s = Schema.new do
        type :array, nil: true do
          type :integer
        end
      end

      assert_nil s.validate!([1, nil, 2])
      assert_verr { s.validate!([1, nil, 'nope']) }
    end

    def test_multiple_arrays
      s = Schema.new do
        type :array, if: proc { |arr| arr&.first&.is_a?(Integer) } do
          type :integer
        end
        type :array, if: proc { |arr| arr&.first&.is_a?(String) } do
          type :string
        end
      end

      assert_nil s.validate!([1, 2, 3])
      assert_nil s.validate!(%w(one two three))
      assert_verr { s.validate!([1, 'mix']) }
      assert_verr { s.validate!([]) }
    end

    def test_multiple_arrays_with_empty
      s = Schema.new do
        type :array, if: proc { |arr| arr&.first&.is_a?(Integer) } do
          type :integer
        end
        type :array, if: proc { |arr| arr&.first&.is_a?(String) } do
          type :string
        end
        type :array
      end

      assert_nil s.validate!([])
      assert_nil s.validate!([1, 2, 3])
      assert_nil s.validate!(%w(one two three))
      assert_verr { s.validate!([1, 'mix']) }
    end
  end
end
