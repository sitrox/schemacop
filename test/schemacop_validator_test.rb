require 'minitest/autorun'
require 'schemacop'

# rubocop: disable Metrics/ClassLength
class SchemacopValidatorTest < Minitest::Test
  def test_top_level_schema
    assert_schema({ type: :integer }, 1)
    assert_schema({ type: :hash, null: true }, nil)
  end

  def test_short_type_schema
    assert_schema({ type: :array, array: :string }, %w(Hello world))
    assert_schema({ array: :string }, %w(Hello world))
    assert_schema({ hash: { first_name: :string, last_name: :string } }, first_name: 'John', last_name: 'Doe')

    assert_schema_failure({ type: :array }, %w(Hello world))
  end

  def test_many_types_schema
    assert_schema({ type: [String, :integer] }, 'Hello world')
    assert_schema({ type: [:string, 'integer'] }, 123)
    assert_schema({ type: String }, 'Hello world')
    assert_schema({ type: :string }, 'Hello world')
    assert_schema({ type: :array, array: :string }, %w(John Doe))
    assert_schema({ type: :hash, hash: { name: :string } }, name: 'John Doe')
    assert_schema({ type: [:array, :hash], array: { type: :string }, hash: { name: :string } }, name: 'John Doe')
    assert_schema({ type: [:array, :hash], array: { type: :string }, hash: { name: :string } }, %w(John Doe))
  end

  def test_unify_schema
    schema_rules = {
      hash: {
        id: [Integer, String],
        name: :string,
        meta: {
          hash: {
            groups: { array: :integer },
            birthday: Date,
            comment: {
              type: :string,
              required: false,
              null: true
            }
          }
        }
      }
    }

    assert_schema(schema_rules, id: 123, name: 'John Doe', meta: { groups: [1, 2, 3], birthday: Date.today, comment: 'Hello world' })
    assert_schema(schema_rules, id: 'XYZ', name: 'John Doe', meta: { groups: [1, 2, 3], birthday: Date.today })
  end

  def test_nested_hash_schema
    schema_rules = {
      type: :hash,
      hash: {
        name: {
          type: :hash,
          hash: {
            first_name: { type: :string },
            last_name: { type: :string }
          }
        }
      }
    }

    assert_schema(schema_rules, name: { first_name: 'John', last_name: 'Doe' })
  end

  def test_flat_hash_old_schema
    schema_rules = {
      type: :hash,
      fields: {
        name: {
          type: :string, null: true
        }
      }
    }

    assert_schema schema_rules, name: 'John Doe'
    assert_schema schema_rules, name: ''
    assert_schema schema_rules, name: nil

    assert_schema_failure schema_rules, name: 123
    assert_schema_failure schema_rules, name: true
    assert_schema_failure schema_rules, name: []
  end

  def test_array_hash_old_schema
    schema_rules = {
      type: :array,
      array: {
        type: :hash,
        fields: {
          required: { type: :boolean },
          name: { type: :string }
        }
      }
    }

    assert_schema schema_rules, [{ name: 'John', required: true }, { name: 'Alex', required: false }]

    assert_schema_failure schema_rules, name: 'John Doe'
    assert_schema_failure schema_rules, [{ name: 'John Doe' }]
    assert_schema_failure schema_rules, [{ required: true }]
    assert_schema_failure schema_rules, [{ name: 0, required: true }]
    assert_schema_failure schema_rules, [{ name: 'John Doe', required: 'string' }]
  end

  def test_fields_array_old_schema
    schema_rules = {
      type: :hash,
      fields: {
        ids: {
          type: :array,
          array: {
            type: :integer
          }
        }
      }
    }

    assert_schema schema_rules, ids: []
    assert_schema schema_rules, ids: [1, 2, 3]

    assert_schema_failure schema_rules, ids: [1, '2']
    assert_schema_failure schema_rules, ids: '3'
    assert_schema_failure schema_rules, ids: nil
  end

  def test_validate_fields_old_schema
    schema_rules = {
      type: :hash,
      fields: {
        name: { type: :string, null: true, required: true },
        age: { type: :integer, required: false, null: true },
        id: { type: :integer, null: false },
        ids: { type: :array, array: { type: :integer }, null: true },
        currency: { type: :string, allowed_values: %w(CHF USD EUR) }
      }
    }

    assert_schema schema_rules, name: 'John', id: 2, ids: [1, 2, 3], currency: 'CHF'
    assert_schema schema_rules, name: nil, id: 2, ids: [1, 2, 3], currency: 'CHF'
    assert_schema schema_rules, name: nil, age: 2, id: 2, ids: nil, currency: 'CHF'
    assert_schema schema_rules, name: nil, id: 2, ids: nil, currency: 'CHF'

    assert_schema_failure schema_rules, id: 2, ids: [1, 2, 3], currency: 'CHF'
    assert_schema_failure schema_rules, name: nil, id: nil, ids: [1, 2, 3], currency: 'CHF'
    assert_schema_failure schema_rules, name: nil, id: 2, ids: [1, 2, 3], currency: 'JPN'
  end

  def test_nested_old_schema
    schema_rules = {
      type: :array,
      array: {
        type: :hash,
        fields: {
          id: { type: :integer },
          hosts: {
            type: :array,
            array: {
              type: :hash,
              fields: {
                hostname: { type: :string }
              }
            }
          }
        }
      }
    }

    assert_schema schema_rules, [
      { id: 1, hosts: [{ hostname: 'localhost' }, { hostname: '127.0.0.1' }] },
      { id: 2, hosts: [{ hostname: '192.168.0.1' }, { hostname: 'somedomain.com' }] }
    ]
  end

  private

  def assert_schema_failure(schema, data)
    assert_raises Schemacop::Exceptions::Validation do
      Schemacop.validate!(schema, data)
    end
  end

  def assert_schema(schema, data)
    begin
      Schemacop.validate!(schema, data)
      success = true
    rescue
      success = false
    end

    assert success
  end
end
