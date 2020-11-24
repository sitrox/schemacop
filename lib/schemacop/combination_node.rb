module Schemacop
  # @abstract
  class CombinationNode < Node
    def self.dsl_methods
      %i[dsl_str dsl_obj dsl_int dsl_num dsl_boo dsl_ary dsl_ref dsl_all_of dsl_any_of dsl_one_of dsl_is_not dsl_add_item]
    end

    def init
      @items = []
    end

    def dsl_str(**options, &block)
      add_item create(:string, **options, &block)
    end

    def dsl_obj(**options, &block)
      add_item create(:object, **options, &block)
    end

    def dsl_int(**options, &block)
      add_item create(:integer, **options, &block)
    end

    def dsl_num(**options, &block)
      add_item create(:number, **options, &block)
    end

    def dsl_boo(**options, &block)
      add_item create(:boolean, **options, &block)
    end

    def dsl_ary(**options, &block)
      add_item create(:array, **options, &block)
    end

    def dsl_ref(path, **options, &block)
      add_item create(:reference, **options.merge(path: path), &block)
    end

    def dsl_all_of(**options, &block)
      add_item create(:all_of, **options, &block)
    end

    def dsl_any_of(**options, &block)
      add_item create(:any_of, **options, &block)
    end

    def dsl_one_of(**options, &block)
      add_item create(:one_of, **options, &block)
    end

    def dsl_is_not(**options, &block)
      add_item create(:is_not, **options, &block)
    end

    def dsl_add_item(node)
      add_item node
    end

    def as_json
      process_json([], type => @items.map(&:as_json))
    end

    def cast(value)
      item = match(value)
      return value unless item
      return item.cast(value)
    end

    protected

    def add_item(node)
      @items << node
    end

    def type
      fail NotImplementedError
    end

    def match(data)
      matches(data).first
    end

    def matches(data)
      @items.filter { |i| item_matches?(i, data) }
    end
  end
end
