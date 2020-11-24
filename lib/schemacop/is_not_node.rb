module Schemacop
  class IsNotNode < CombinationNode
    def type
      :not
    end

    def add_item(node)
      if @items.any?
        fail 'Node is_not only allows exactly one item.'
      end

      @items << node
    end

    def _validate(data, result:)
      return if data.nil?

      if matches(data).any?
        result.error "Must not match schema: #{@items.first.as_json.as_json.inspect}."
      end

      super
    end

    def cast(data)
      data
    end
  end
end