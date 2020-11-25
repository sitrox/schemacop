require 'test_helper'

module Schemacop
  class ReferenceNodeTest < V3Test
    # def test_in_object
    #   context = Schemacop::Context.new
    #   context.schema :MyString, :string
    #   context.schema :MyInteger, :integer
    #
    #   Schemacop.with_context context do
    #     schema do
    #       ref? :foo, :MyString
    #       ref? :int, :MyInteger
    #       obj? :bar do
    #         ref? :foo, :MyString
    #         obj? :baz do
    #           ref! :foo, :MyInteger
    #         end
    #       end
    #     end
    #
    #     assert_validation({})
    #     assert_validation(foo: 'String')
    #     assert_validation(bar: { foo: 'String' })
    #     assert_validation(bar: { foo: 'String', baz: { foo: 42 } })
    #
    #     assert_validation(foo: 42) do
    #       error '/foo', 'Invalid type, expected "string".'
    #     end
    #     assert_validation(bar: { foo: 42 }) do
    #       error '/bar/foo', 'Invalid type, expected "string".'
    #     end
    #     assert_validation(bar: { foo: 'String', baz: { foo: '42' } }) do
    #       error '/bar/baz/foo', 'Invalid type, expected "integer".'
    #     end
    #   end
    # end
    #
    # def test_schema_not_found
    #   assert_raises_with_message RuntimeError, 'Schema "MyInteger" not found.' do
    #     schema do
    #       ref? :int, :MyInteger
    #     end
    #     assert_validation(int: 5)
    #   end
    # end
    #
    # def test_in_object_recursion
    #   schema do
    #     scm :Node do
    #       str! :name
    #       ary? :children, min_items: 1 do
    #         ref :Node
    #       end
    #     end
    #
    #     ref? :node, :Node
    #   end
    #
    #   assert_validation({})
    #   assert_validation(node: { name: '1', children: [{ name: '1' }, { name: '2' }] })
    #   assert_validation(
    #     node: {
    #       name:     '1',
    #       children: [
    #         { name: '1.1' },
    #         {
    #           name:     '1.2',
    #           children: [
    #             { name: '1.2.1' }
    #           ]
    #         }
    #       ]
    #     }
    #   )
    #
    #   assert_validation(
    #     node: {
    #       name:     '1',
    #       children: [
    #         { name: '1.1' },
    #         {
    #           name:     '1.2',
    #           children: [
    #             { name: '1.2.1', children: [] }
    #           ]
    #         },
    #         { name: '1.3', foo: :bar }
    #       ]
    #     }
    #   ) do
    #     error '/node/children/[1]/children/[0]/children', 'Array has 0 items but needs at least 1.'
    #     error '/node/children/[2]', 'Obsolete property "foo".'
    #   end
    # end
    #
    # def test_external_schemas
    #   context = Context.new
    #
    #   context.schema :Person do
    #     str! :first_name
    #     str! :last_name
    #     ref? :info, :PersonInfo
    #   end
    #
    #   context.schema :PersonInfo do
    #     str! :born_at, format: :date
    #   end
    #
    #   schema :reference, path: :Person
    #
    #   with_context context do
    #     assert_validation(first_name: 'John', last_name: 'Doe')
    #     assert_validation(first_name: 'John', last_name: 42) do
    #       error '/last_name', 'Invalid type, expected "string".'
    #     end
    #   end
    #
    #   with_context context do
    #     schema do
    #       ref! :person, :Person
    #     end
    #
    #     assert_validation(person: { first_name: 'John', last_name: 'Doe' })
    #     assert_validation(person: { first_name: 'John', last_name: 'Doe', info: { born_at: '1990-01-13' } })
    #     assert_validation(person: { first_name_x: 'John', last_name: 'Doe' }) do
    #       error '/person', 'Obsolete property "first_name_x".'
    #       error '/person/first_name', 'Value must be given.'
    #     end
    #     assert_validation(person: { first_name: 'John', last_name: 'Doe', info: { born_at: 'never' } }) do
    #       error '/person/info/born_at', 'String does not match format "date".'
    #     end
    #   end
    # end

    def test_defaults
      schema do
        scm :Person do
          str? :foo, default: 'bar'
        end
        ref? :person, :Person, default: {}
      end

      assert_cast({}, person: { foo: 'bar' })
    end

    # def test_casting
    #   schema do
    #     scm :Person do
    #       str! :born_at, format: :date
    #     end
    #     ref? :person, :Person, default: {}
    #   end
    #
    #   assert_cast({ person: { born_at: '1990-01-13' } }, person: { born_at: Date.new(1990, 01, 13) })
    # end
  end
end
