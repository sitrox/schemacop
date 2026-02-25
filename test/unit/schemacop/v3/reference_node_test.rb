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

      # --- Inline ref tests ---

      def test_inline_ref_schema_builds_without_error
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
        end

        assert_equal [], @schema.root.properties.keys
        assert_equal 1, @schema.root.inline_refs.size
      end

      def test_inline_ref_validation
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
          str! :extra
        end

        assert_validation(id: 1, name: 'John', extra: 'info')
      end

      def test_inline_ref_validation_errors
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
          str! :extra
        end

        assert_validation(extra: 'info') do
          error '/id', 'Value must be given.'
          error '/name', 'Value must be given.'
        end
      end

      def test_inline_ref_validation_type_errors
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
        end

        assert_validation(id: 'not_an_int', name: 42) do
          error '/id', 'Invalid type, got type "String", expected "integer".'
          error '/name', 'Invalid type, got type "Integer", expected "string".'
        end
      end

      def test_inline_ref_validation_obsolete_properties
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
        end

        # Properties from inline ref are accepted
        assert_validation(id: 1, name: 'John')

        # Unknown properties are still rejected
        assert_validation(id: 1, name: 'John', unknown: 'value') do
          error '/', 'Obsolete property "unknown".'
        end
      end

      def test_inline_ref_cast
        schema do
          scm :BasicInfo do
            str! :born_at, format: :date
            str! :name
          end

          ref! nil, :BasicInfo
          str! :extra
        end

        assert_cast(
          { born_at: '1990-01-13', name: 'John', extra: 'info' },
          { born_at: Date.new(1990, 1, 13), name: 'John', extra: 'info' }.with_indifferent_access
        )
      end

      def test_inline_ref_with_defaults
        schema do
          scm :BasicInfo do
            str? :name, default: 'Anonymous'
          end

          ref! nil, :BasicInfo
        end

        assert_cast({}, { name: 'Anonymous' }.with_indifferent_access)
      end

      def test_inline_ref_with_optional_properties
        schema do
          scm :BasicInfo do
            int! :id
            str? :nickname
          end

          ref! nil, :BasicInfo
        end

        assert_validation(id: 1)
        assert_validation(id: 1, nickname: 'Johnny')
      end

      def test_inline_ref_as_json
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
          str! :extra
        end

        assert_json({
                      definitions: {
                        BasicInfo: {
                          properties:           {
                            id:   { type: :integer },
                            name: { type: :string }
                          },
                          additionalProperties: false,
                          required:             %w[id name],
                          type:                 :object
                        }
                      },
                      type:        :object,
                      allOf:       [
                        { '$ref' => '#/definitions/BasicInfo' },
                        {
                          type:                 :object,
                          properties:           {
                            extra: { type: :string }
                          },
                          additionalProperties: false,
                          required:             %w[extra]
                        }
                      ]
                    })
      end

      def test_inline_ref_as_json_no_own_properties
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
        end

        assert_json({
                      definitions: {
                        BasicInfo: {
                          properties:           {
                            id:   { type: :integer },
                            name: { type: :string }
                          },
                          additionalProperties: false,
                          required:             %w[id name],
                          type:                 :object
                        }
                      },
                      type:        :object,
                      allOf:       [
                        { '$ref' => '#/definitions/BasicInfo' }
                      ]
                    })
      end

      def test_inline_ref_swagger_json
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
          str! :extra
        end

        assert_swagger_json({
                              type:  :object,
                              allOf: [
                                { '$ref' => '#/components/schemas/BasicInfo' },
                                {
                                  type:                 :object,
                                  properties:           {
                                    extra: { type: :string }
                                  },
                                  additionalProperties: false,
                                  required:             %w[extra]
                                }
                              ]
                            })
      end

      def test_inline_ref_multiple
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          scm :Timestamps do
            str! :created_at, format: :date
          end

          ref! nil, :BasicInfo
          ref! nil, :Timestamps
          str! :extra
        end

        # Validation
        assert_validation(id: 1, name: 'John', created_at: '2024-01-01', extra: 'info')
        assert_validation(extra: 'info') do
          error '/id', 'Value must be given.'
          error '/name', 'Value must be given.'
          error '/created_at', 'Value must be given.'
        end

        # Casting
        assert_cast(
          { id: 1, name: 'John', created_at: '2024-01-01', extra: 'info' },
          { id: 1, name: 'John', created_at: Date.new(2024, 1, 1), extra: 'info' }.with_indifferent_access
        )

        # JSON
        assert_json({
                      definitions: {
                        BasicInfo:  {
                          properties:           {
                            id:   { type: :integer },
                            name: { type: :string }
                          },
                          additionalProperties: false,
                          required:             %w[id name],
                          type:                 :object
                        },
                        Timestamps: {
                          properties:           {
                            created_at: { type: :string, format: :date }
                          },
                          additionalProperties: false,
                          required:             %w[created_at],
                          type:                 :object
                        }
                      },
                      type:        :object,
                      allOf:       [
                        { '$ref' => '#/definitions/BasicInfo' },
                        { '$ref' => '#/definitions/Timestamps' },
                        {
                          type:                 :object,
                          properties:           {
                            extra: { type: :string }
                          },
                          additionalProperties: false,
                          required:             %w[extra]
                        }
                      ]
                    })
      end

      def test_inline_ref_with_external_schema
        context = Context.new

        context.schema :BasicInfo do
          int! :id
          str! :name
        end

        with_context context do
          schema do
            ref! nil, :BasicInfo
            str! :extra
          end

          assert_validation(id: 1, name: 'John', extra: 'info')
          assert_validation(extra: 'info') do
            error '/id', 'Value must be given.'
            error '/name', 'Value must be given.'
          end
        end
      end

      def test_inline_ref_used_external_schemas
        context = Context.new

        context.schema :BasicInfo do
          int! :id
          str! :name
        end

        with_context context do
          schema do
            ref! nil, :BasicInfo
            str! :extra
          end

          assert_equal %i[BasicInfo], @schema.root.used_external_schemas
        end
      end

      def test_inline_ref_with_additional_properties_true
        schema do
          scm :BasicInfo do
            int! :id
            str! :name
          end

          ref! nil, :BasicInfo
          str! :extra
        end

        # Without additional_properties: true, unknown props are rejected
        assert_validation(id: 1, name: 'John', extra: 'info', unknown: 'value') do
          error '/', 'Obsolete property "unknown".'
        end
      end

      def test_namespaced_schema_reference
        context = Context.new

        context.schema :'namespaced/user' do
          str! :name
        end

        Schemacop.with_context context do
          schema do
            ref! :user, :'namespaced/user'
          end

          assert_json({
                        properties:           {
                          user: {
                            '$ref' => '#/definitions/namespaced~1user'
                          }
                        },
                        additionalProperties: false,
                        required:             %w[user],
                        type:                 :object
                      })

          assert_swagger_json({
                                properties:           {
                                  user: {
                                    '$ref' => '#/components/schemas/namespaced.user'
                                  }
                                },
                                additionalProperties: false,
                                required:             %w[user],
                                type:                 :object
                              })

          assert_validation(user: { name: 'John' })
          assert_validation(user: { name: 42 }) do
            error '/user/name', 'Invalid type, got type "Integer", expected "string".'
          end
        end
      end

      def test_namespaced_schema_reference_with_tilde
        context = Context.new

        context.schema :'config~item/sub' do
          str! :value
        end

        Schemacop.with_context context do
          schema do
            ref! :item, :'config~item/sub'
          end

          assert_json({
                        properties:           {
                          item: {
                            '$ref' => '#/definitions/config~0item~1sub'
                          }
                        },
                        additionalProperties: false,
                        required:             %w[item],
                        type:                 :object
                      })

          assert_swagger_json({
                                properties:           {
                                  item: {
                                    '$ref' => '#/components/schemas/config.item.sub'
                                  }
                                },
                                additionalProperties: false,
                                required:             %w[item],
                                type:                 :object
                              })

          assert_validation(item: { value: 'hello' })
        end
      end

      def test_ref_inside_one_of_used_external_schemas
        context = Context.new

        context.schema :Nested do
          str! :value
        end

        Schemacop.with_context context do
          schema do
            one_of! :item do
              ref :Nested
              str
            end
          end

          assert_includes @schema.root.used_external_schemas, :Nested
        end
      end

      def test_inline_ref_property_name_collision
        schema do
          scm :BasicInfo do
            str! :name
            str? :description
          end

          ref! nil, :BasicInfo
          int! :name # Direct property takes precedence
        end

        # Direct property (int!) takes precedence — string should fail
        assert_validation(name: 42)
        assert_validation(name: 'John') do
          error '/name', 'Invalid type, got type "String", expected "integer".'
        end

        # Optional description from inline ref still works
        assert_validation(name: 42, description: 'A description')
      end

      def test_inline_ref_collision_between_inline_refs
        schema do
          scm :BasicInfo do
            str! :name
            str? :description
          end

          scm :ExtraInfo do
            int! :name # Clashes with BasicInfo's :name
            str! :extra
          end

          ref! nil, :BasicInfo # First inline ref wins for :name
          ref! nil, :ExtraInfo
        end

        # First inline ref wins: :name is validated as str! (from BasicInfo)
        assert_validation(name: 'John', extra: 'info')
        assert_validation(name: 42, extra: 'info') do
          error '/name', 'Invalid type, got type "Integer", expected "string".'
        end

        # Properties unique to second inline ref still work
        assert_validation(name: 'John') do
          error '/extra', 'Value must be given.'
        end

        # Casting uses first inline ref's definition for :name
        assert_cast(
          { name: 'John', description: 'A desc', extra: 'info' },
          { name: 'John', description: 'A desc', extra: 'info' }.with_indifferent_access
        )
      end
    end
  end
end
