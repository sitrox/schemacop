require 'test_helper'

module Schemacop
  module V3
    class NodeTest < V3Test
      def test_cast_in_root
        schema :integer, cast_str: true, required: true

        assert_json(
          oneOf: [
            { type: :integer },
            { type: :string, format: :integer }
          ]
        )

        assert_validation(5)

        assert_validation(nil) do
          error '/', 'Value must be given.'
        end

        assert_validation('5')
        assert_validation('5.3') do
          error '/', 'Matches 0 definitions but should match exactly 1.'
        end

        assert_cast(5, 5)
        assert_cast('5', 5)
      end

      def test_cast_in_array
        schema :array do
          num cast_str: true, minimum: 3
        end

        assert_json(
          type:            :array,
          items:           [
            {
              oneOf: [
                { type: :number, minimum: 3 },
                { type: :string, format: :number }
              ]
            }
          ],
          additionalItems: false
        )

        assert_validation([5, 5.3, '42.0', '42.42'])
        assert_validation([5, 5.3, '42.0', '42.42', 'bar']) do
          error '/[4]', 'Matches 0 definitions but should match exactly 1.'
        end
        assert_validation([2]) do
          error '/[0]', 'Matches 0 definitions but should match exactly 1.'
        end
        assert_validation(['2']) do
          error '/[0]', 'Matches 0 definitions but should match exactly 1.'
        end

        # TODO: Enable this test again once fixed
        # assert_validation([nil]) do
        #   error '/[0]', 'Matches 0 definitions but should match exactly 1.'
        # end
      end
    end
  end
end
