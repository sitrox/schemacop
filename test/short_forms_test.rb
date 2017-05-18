require 'test_helper'

module Schemacop
  class ShortFormsTest < Minitest::Test
    class User; end
    class Group; end

    def test_constructor_defaults_to_hash
      s = Schema.new do
        req! :r do
          type :integer
        end
        opt? :o do
          type :integer
        end
      end

      assert_nil s.validate!(r: 3)
      assert_nil s.validate!(r: 3, o: 1)
      assert_verr { s.validate!(o: 1) }
      assert_verr { s.validate!(1) }
      assert_verr { s.validate!(r: 3, n: 5) }
    end

    def test_field_defaults_to_any
      s = Schema.new do
        type :hash do
          req :r
          opt :o
        end
      end

      assert_nil s.validate!(r: 3)
      assert_nil s.validate!(r: 'asd', o: self)
      assert_verr { s.validate!(o: -5.3) }
      assert_verr { s.validate!(Class) }
      assert_verr { s.validate!(r: s, n: true) }
    end

    def test_inline_type_with_attrs_in_hash
      s = Schema.new do
        type :hash do
          req :i, :integer, min: 5
          opt :f, :float, min: 2.3, max: 3
        end
      end

      assert_nil s.validate!(i: 5)
      assert_nil s.validate!(i: 5, f: 2.3)
      assert_verr { s.validate!(i: 4, f: 2.3) }
      assert_verr { s.validate!(i: 5, f: 2.2) }
      assert_verr { s.validate!(i: 5, f: 3.4) }
      assert_verr { s.validate!(i: 5.3) }
      assert_verr { s.validate!(j: 2.3) }
      assert_verr { s.validate!({}) }
    end

    def test_inline_type_in_constructor
      s = Schema.new :integer, min: 2, max: 4
      assert_nil s.validate!(3)
      assert_verr { s.validate!(5) }
      assert_verr { s.validate!(1) }
    end

    def test_mixed_field_and_type_attrs
      s = Schema.new do
        req? :nilbool, :boolean
        req? :nilint, :integer, min: 2, max: 3
        opt! :optint, :integer, min: 2, max: 3
      end

      assert_nil s.validate!(nilbool: nil, nilint: nil)
      assert_nil s.validate!(nilbool: false, nilint: 2)
      assert_nil s.validate!(nilbool: false, nilint: 3, optint: 2)
      assert_verr { s.validate!(nilbool: false, nilint: 2, optint: nil) }
      assert_verr { s.validate!(nilbool: false, nilint: 2, optint: 4) }
      assert_verr { s.validate!(nilbool: false, nilint: -5, optint: 2) }
    end

    def test_array_shortform_simple
      s = Schema.new do
        type(:array, :string)
      end
      assert_nil s.validate!(%w(a b))
    end

    # TODO: Get the exception message into the assertion
    def test_array_shortform_invalid
      assert_raises Exceptions::InvalidSchemaError do
        Schema.new do
          type(:array, [:array, :integer], min: 2)
        end
      end
    end

    def test_array_shortform_advanced1
      s = Schema.new do
        type(:array, [:array, :integer])
      end
      assert_nil s.validate! [[], 3]
      assert_nil s.validate! [[:a, 9], 3]
      assert_nil s.validate! [[]]
      assert_nil s.validate! [3]
      assert_verr { s.validate! [[], 'string'] }
      assert_verr { s.validate! [3, 'string'] }
      assert_verr { s.validate! ['string'] }
    end

    def test_array_shortform_advanced2
      assert_raises Exceptions::InvalidSchemaError, 'No validation class found for type [:array, :integer].' do
        Schema.new do
          type([:array, [:array, :integer], :boolean])
        end
      end
    end

    # For explicit form test see types_test.rb
    def test_array_subtype_shortform
      s = Schema.new do
        type :array, :integer
      end
      assert_nil s.validate! [5]
      assert_verr { s.validate! [nil] }
      assert_verr { s.validate! ['a'] }
      assert_verr { s.validate! [5, 'a'] }
      assert_verr { s.validate! [5, nil] }
    end

    def test_array_subsubtype_shortform
      s = Schema.new do
        type :array, :array, :integer
      end
      assert_nil s.validate! [[5]]
      assert_verr { s.validate! [5] }
      assert_verr { s.validate! [[nil]] }
      assert_verr { s.validate! [['a']] }
      assert_verr { s.validate! [[5, 'a']] }
      assert_verr { s.validate! [[5, nil]] }
    end

    def test_wild_mix_should_pass
      s = Schema.new do
        req :foo do
          req? :bar, :object, classes: NilClass
        end
        req :name, :integer, min: 5, max: 7
        req :id, [:integer, :string]
        req :callback, :symbol
        req :attrs do
          req :color do
            type :integer
          end
        end
        req :colors, :array, [:string, :integer]
        req :cars, :array, :hash do
          req? :years, :array, :integer
          req! :make, :string
          req! :ps, :integer
          req? :electric, :boolean
        end
      end

      assert_nil s.validate!(
        name: 6,
        foo: { bar: nil },
        attrs: { color: 5 },
        id: 'hallo',
        callback: :funky_function,
        colors: [5, 'sdf'],
        cars: [
          {
            make: 'Tesla',
            ps: 5,
            electric: nil,
            years: [1993, 1990]
          }
        ]
      )
    end

    def test_super_deep_wild_should_pass
      s = Schema.new do
        type :hash do
          opt? :bla do
            type :string
          end
          req :id do
            type :string
          end
          req? :friends do
            type :array do
              type :string, min: 3, max: 6
              type :boolean
              type :hash do
                req :rod do
                  type :hash do
                    req :fritz do
                      type :array, min: 2 do
                        type :array do
                          type :integer, min: 1
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        type :integer, min: 3
      end

      assert_nil s.validate!(
        id: 'meine ID',
        friends: [
          'Rodney',
          true,
          false,
          {
            rod: {
              fritz:
              [
                [1],
                [3]
              ]
            }
          }
        ]
      )
      assert_nil s.validate!(id: 'my ID', friends: nil)
      assert_nil s.validate!(3)
    end

    def test_example_from_readme
      schema = Schema.new do
        req :naming, :hash do
          opt :first_name, :string
          req :last_name, :string
        end
        opt! :age, :integer, min: 18
        req? :password do
          type :string, check: proc { |pw| pw.include?('*') }
          type :integer
        end
      end

      assert_nil schema.validate!(
        naming: { first_name: 'John',
                  last_name: 'Doe' },
        age: 34,
        password: 'my*pass'
      )

      assert_verr do
        schema.validate!(
          naming: { first_name: 'John',
                    last_name: 'Doe' },
          age: 12,
          password: 'my*pass'
        )
      end
      assert_verr do
        schema.validate!(
          naming: { first_name: 'John',
                    last_name: 'Doe' },
          age: 12,
          password: 'mypass'
        )
      end

      schema2 = Schema.new do
        req :description,
            :string,
            if: proc { |str| str.start_with?('Abstract: ') },
            max: 35,
            check: proc { |str| !str.end_with?('.') }
        req :description, :string, min: 35
      end

      assert_nil schema2.validate!(description: 'Abstract: a short description')
      assert_nil schema2.validate!(description: 'Since this is no abstract, we expect it to be longer.')
      assert_verr { schema2.validate!(description: 'Abstract: A short description.') }
      assert_verr { schema2.validate!(description: 'Abstract: This is gonna be way way too long for an abstract.') }
      assert_verr { schema2.validate!(description: 'This is too short.') }
    end

    def test_one_line_subtype_with_options
      s = Schema.new do
        type :array, :integer, min: 3
      end
      assert_nil s.validate!([3])
      assert_nil s.validate!([3, 4, 5])
      assert_verr { s.validate!([3, 2]) }
      assert_verr { s.validate!([5, 'string']) }
    end

    def test_one_line_array_schema
      s = Schema.new :array, :integer, min: 3
      assert_nil s.validate!([3])
      assert_nil s.validate!([3, 4, 5])
      assert_verr { s.validate!([3, 2]) }
      assert_verr { s.validate!([5, 'string']) }
    end

    def test_implicit_hash
      s = Schema.new do
        req :bar
      end
      assert_nil s.validate!(bar: 2)
      assert_verr { s.validate!(foo: 2) }
      assert_verr { s.validate!([2]) }
    end

    def test_one_line_string_schema
      s = Schema.new :string, min: 4
      assert_nil s.validate!('1234')
      assert_verr { s.validate!('123') }
      assert_verr { s.validate!(string: '1234') }
    end

    def test_inline_objects
      s = Schema.new do
        req :user, User
        req :group, Group
      end

      assert_nil s.validate!(user: User.new, group: Group.new)
      assert_verr { s.validate!(user: Group.new, group: User.new) }
    end
  end
end
