module Schemacop::V2
  class NodeWithBlock < Node
    class_attribute :block_methods
    self.block_methods = [].freeze

    def self.block_method(name)
      self.block_methods += [name]
    end

    def exec_block(&block)
      return unless block_given?
      se = Schemacop::ScopedEnv.new(self, self.class.block_methods)
      se.instance_exec(&block)
    end
  end
end
