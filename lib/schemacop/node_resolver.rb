module Schemacop
  class NodeResolver
    class_attribute :node_classes
    self.node_classes = [].freeze

    def self.register(node_class)
      self.node_classes += [node_class]
    end

    def self.resolve(type)
      node_classes.find { |c| c.type_matches?(type) }
    end
  end
end
