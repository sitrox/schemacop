require 'test_helper'

module Schemacop::V2
  class NodeResolverTest < Minitest::Test
    class ClassA; end
    class ClassB; end
    class ClassC; end
    class ClassD; end

    def test_insert_before
      prev_node_classes = NodeResolver.node_classes

      NodeResolver.node_classes = []

      NodeResolver.register(ClassA)
      NodeResolver.register(ClassB)
      NodeResolver.register(ClassC)
      NodeResolver.register(ClassD, before: ClassB)

      assert_equal [ClassA, ClassD, ClassB, ClassC],
                   NodeResolver.node_classes
    ensure
      NodeResolver.node_classes = prev_node_classes
    end
  end
end
