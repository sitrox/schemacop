require 'test_helper'

module Schemacop::V2
  class CollectorTest < Minitest::Test
    def test_no_root_node
      s = Schema.new do
        req :a, :string
      end

      col = s.validate(a: 0)
      assert col.exceptions.first[:path].first !~ %r{^/root}, 'Root node is present in the path.'
    end

    def test_correct_path
      s = Schema.new do
        req :long_symbol, :string
        req 'long_string', :string
        req 123, :string
      end

      col = s.validate('long_string' => 0, long_symbol: 0, 123 => 0)

      symbol = col.exceptions[0]
      string = col.exceptions[1]
      number = col.exceptions[2]

      assert symbol[:path].first =~ %r{^/long_symbol}
      assert string[:path].first =~ %r{^/long_string}
      assert number[:path].first =~ %r{^/123}
    end

    def test_nested_paths
      s = Schema.new do
        req :one do
          req :two, :string
        end
        req :three, :string
      end

      col = s.validate(one: { two: 0 }, three: 0)
      assert_equal 2, col.exceptions[0][:path].length
      assert_equal 1, col.exceptions[1][:path].length
    end
  end
end
