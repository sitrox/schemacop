require 'test_helper'

module Schemacop
  module V3
    class IsNotNodeTest < V3Test
      def test_optional
        schema :is_not do
          int minimum: 5
        end

        assert_validation(nil)
        assert_validation({})
        assert_validation(:foo)
        assert_validation(4)
        assert_validation(8) do
          error '/', 'Must not match schema: {"type"=>"integer", "minimum"=>5}.'
        end
      end

      def test_required
        schema :is_not, required: true do
          int minimum: 5
        end

        assert_json(
          not: { type: :integer, minimum: 5 }
        )

        assert_validation(:foo)
        assert_validation(4)
        assert_validation(nil) do
          error '/', 'Value must be given.'
        end
        assert_validation({})
        assert_validation(8) do
          error '/', 'Must not match schema: {"type"=>"integer", "minimum"=>5}.'
        end
      end
    end
  end
end
