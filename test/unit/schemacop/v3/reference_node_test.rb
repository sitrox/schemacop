require 'test_helper'

module Schemacop
  module V3
    class ReferenceNodeTest < V3Test
      def test_in_hash
        context = Context.new
        context.schema :MyString, :string
        context.schema :MyInteger, :integer

        Schemacop.with_context context do
          schema do
            ref? :foo, :MyString
            ref? :int, :MyInteger
            hsh? :bar do
              ref? :foo, :MyString
              hsh? :baz do
                ref! :foo, :MyInteger
              end
            end
          end

          assert_validation({})
          assert_validation(foo: 'String')
          assert_validation(bar: { foo: 'String' })
          assert_validation(bar: { foo: 'String', baz: { foo: 42 } })

          assert_validation(foo: 42) do
            error '/foo', 'Invalid type, got type "Integer", expected "string".'
          end
          assert_validation(bar: { foo: 42 }) do
            error '/bar/foo', 'Invalid type, got type "Integer", expected "string".'
          end
          assert_validation(bar: { foo: 'String', baz: { foo: '42' } }) do
            error '/bar/baz/foo', 'Invalid type, got type "String", expected "integer".'
          end

          assert_json({
                        properties:           {
                          foo: {
                            '$ref' => '#/definitions/MyString'
                          },
                          int: {
                            '$ref' => '#/definitions/MyInteger'
                          },
                          bar: {
                            properties:           {
                              foo: {
                                '$ref' => '#/definitions/MyString'
                              },
                              baz: {
                                properties:           {
                                  foo: {
                                    '$ref' => '#/definitions/MyInteger'
                                  }
                                },
                                additionalProperties: false,
                                required:             ['foo'],
                                type:                 :object
                              }
                            },
                            additionalProperties: false,
                            type:                 :object
                          }
                        },
                        additionalProperties: false,
                        type:                 :object
                      })
        end
      end

      def test_schema_not_found
        assert_raises_with_message RuntimeError, 'Schema "MyInteger" not found.' do
          schema do
            ref? :int, :MyInteger
          end
          assert_validation(int: 5)
        end
      end

      def test_multiple_schemas
        schema do
          scm :Address do
            str! :street
            str! :zip_code
            str! :location
            str! :country
          end

          scm :Person do
            str! :first_name
            str! :last_name
            str! :birthday, format: :date
          end

          ref! :person_info, :Person
          ref! :shipping_address, :Address
          ref! :billing_address, :Address
        end

        assert_json({
                      definitions:          {
                        Address: {
                          properties:           {
                            street:   {
                              type: :string
                            },
                            zip_code: {
                              type: :string
                            },
                            location: {
                              type: :string
                            },
                            country:  {
                              type: :string
                            }
                          },
                          additionalProperties: false,
                          required:             %w[street zip_code location country],
                          type:                 :object
                        },
                        Person:  {
                          properties:           {
                            first_name: {
                              type: :string
                            },
                            last_name:  {
                              type: :string
                            },
                            birthday:   {
                              type:   :string,
                              format: :date
                            }
                          },
                          additionalProperties: false,
                          required:             %w[first_name last_name birthday],
                          type:                 :object
                        }
                      },
                      properties:           {
                        person_info:      {
                          '$ref' => '#/definitions/Person'
                        },
                        shipping_address: {
                          '$ref' => '#/definitions/Address'
                        },
                        billing_address:  {
                          '$ref' => '#/definitions/Address'
                        }
                      },
                      type:                 :object,
                      additionalProperties: false,
                      required:             %w[
                        person_info
                        shipping_address
                        billing_address
                      ]
                    })

        assert_validation(nil)
        assert_validation({
                            person_info:      {
                              first_name: 'Joe',
                              last_name:  'Doe',
                              birthday:   '1990-01-01'
                            },
                            billing_address:  {
                              street:   'Badenerstrasse 530',
                              zip_code: '8048',
                              location: 'Zürich',
                              country:  'Switzerland'
                            },
                            shipping_address: {
                              street:   'Badenerstrasse 530',
                              zip_code: '8048',
                              location: 'Zürich',
                              country:  'Switzerland'
                            }
                          })

        assert_validation({}) do
          error '/person_info', 'Value must be given.'
          error '/shipping_address', 'Value must be given.'
          error '/billing_address', 'Value must be given.'
        end
      end

      def test_nested_schemas
        schema do
          scm :User do
            str! :first_name
            str! :last_name
            ary? :groups do
              list :reference, path: :Group
            end
          end

          scm :Group do
            str! :name
          end
        end

        assert_json({
                      additionalProperties: false,
                      definitions:          {
                        User:  {
                          properties:           {
                            first_name: {
                              type: :string
                            },
                            last_name:  {
                              type: :string
                            },
                            groups:     {
                              type:  :array,
                              items: {
                                '$ref' => '#/definitions/Group'
                              }
                            }
                          },
                          additionalProperties: false,
                          required:             %w[first_name last_name],
                          type:                 :object
                        },
                        Group: {
                          properties:           {
                            name: {
                              type: :string
                            }
                          },
                          additionalProperties: false,
                          required:             ['name'],
                          type:                 :object
                        }
                      },
                      type:                 :object
                    })
      end

      def test_in_hash_recursion
        schema do
          scm :Node do
            str! :name
            ary? :children, min_items: 1 do
              list :reference, path: :Node
            end
          end

          ref? :node, :Node
        end

        assert_equal(@schema.root.used_external_schemas, [])

        assert_validation({})
        assert_validation(node: { name: '1', children: [{ name: '1' }, { name: '2' }] })
        assert_validation(
          node: {
            name:     '1',
            children: [
              { name: '1.1' },
              {
                name:     '1.2',
                children: [
                  { name: '1.2.1' }
                ]
              }
            ]
          }
        )

        assert_validation(
          node: {
            name:     '1',
            children: [
              { name: '1.1' },
              {
                name:     '1.2',
                children: [
                  { name: '1.2.1', children: [] }
                ]
              },
              { name: '1.3', foo: :bar }
            ]
          }
        ) do
          error '/node/children/[1]/children/[0]/children', 'Array has 0 items but needs at least 1.'
          error '/node/children/[2]', 'Obsolete property "foo".'
        end
      end

      def test_external_schemas
        context = Context.new

        context.schema :Person do
          str! :first_name
          str! :last_name
          ref? :info, :PersonInfo
        end

        context.schema :PersonInfo do
          str! :born_at, format: :date
        end

        schema :reference, path: :Person

        with_context context do
          assert_validation(first_name: 'John', last_name: 'Doe')
          assert_validation(first_name: 'John', last_name: 42) do
            error '/last_name', 'Invalid type, got type "Integer", expected "string".'
          end
        end

        with_context context do
          schema do
            ref! :person, :Person
          end

          assert_equal(@schema.root.used_external_schemas, %i[Person PersonInfo])

          assert_validation(person: { first_name: 'John', last_name: 'Doe' })
          assert_validation(person: { first_name: 'John', last_name: 'Doe', info: { born_at: '1990-01-13' } })
          assert_validation(person: { first_name_x: 'John', last_name: 'Doe' }) do
            error '/person', 'Obsolete property "first_name_x".'
            error '/person/first_name', 'Value must be given.'
          end
          assert_validation(person: { first_name: 'John', last_name: 'Doe', info: { born_at: 'never' } }) do
            error '/person/info/born_at', 'String does not match format "date".'
          end
        end

        with_context context do
          schema do
            scm :PersonNode do
              ref! :person, :Person
            end

            ref! :personNode, :PersonNode
          end

          assert_equal(@schema.root.used_external_schemas, %i[Person PersonInfo])
        end
      end

      def test_defaults
        schema do
          scm :Person do
            str? :foo, default: 'bar'
          end
          ref? :person, :Person, default: {}
        end

        assert_cast({}, { person: { foo: 'bar' } }.with_indifferent_access)
      end

      def test_casting
        schema do
          scm :Person do
            str! :born_at, format: :date
          end
          ref? :person, :Person, default: {}
        end

        assert_cast({ person: { born_at: '1990-01-13' } }, { person: { born_at: Date.new(1990, 1, 13) } }.with_indifferent_access)
      end
    end
  end
end
