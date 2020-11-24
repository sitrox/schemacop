module Schemacop::V2
  class NodeResolver
    class_attribute :node_classes
    self.node_classes = [].freeze

    def self.register(node_class, before: nil)
      if before
        unless (index = node_classes.find_index(before))
          fail "Cannot insert before class #{before} which has not been registered yet."
        end

        node_classes.insert(index, node_class)
      else
        self.node_classes += [node_class]
      end
    end

    def self.resolve(type)
      node_classes.find { |c| c.type_matches?(type) }
    end
  end
end
