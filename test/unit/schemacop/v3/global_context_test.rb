require 'test_helper'

module Schemacop
  module V3
    class GlobalContextTest < V3Test
      def setup
        super
        GlobalContext.instance_variable_set(:@instance, GlobalContext.send(:new))
        Schemacop.load_paths = ['test/schemas']
      end

      def test_instance
        assert_equal GlobalContext.instance, GlobalContext.instance
      end

      def test_eager_load
        refute GlobalContext.instance.instance_variable_get(:@eager_loaded)
        GlobalContext.instance.eager_load!
        assert GlobalContext.instance.instance_variable_get(:@eager_loaded)

        assert_raises_with_message RuntimeError, /can't be eager loaded more than once/ do
          GlobalContext.instance.eager_load!
        end
      end

      def test_schemas
        assert_equal({}, GlobalContext.instance.schemas)
        assert_equal({}, GlobalContext.schemas)
        GlobalContext.instance.eager_load!
        assert_equal(%i[nested/group user], GlobalContext.instance.schemas.keys)
        assert_equal(%i[nested/group user], GlobalContext.schemas.keys)
        assert_is_a Node, GlobalContext.instance.schemas.values.first
      end

      def test_schema_for_w_eager_loading
        GlobalContext.instance.eager_load!

        2.times do
          assert_is_a HashNode, GlobalContext.instance.schema_for('user')
          assert_equal(%i[nested/group user], GlobalContext.instance.schemas.keys)
          assert_is_a HashNode, GlobalContext.instance.schema_for('user')
        end
      end

      def test_schema_for_wo_eager_loading
        assert_is_a HashNode, GlobalContext.instance.schema_for('user')
        assert_equal(%i[user], GlobalContext.instance.schemas.keys)
        assert_is_a HashNode, GlobalContext.instance.schema_for('user')
        assert_is_a HashNode, GlobalContext.instance.schema_for('nested/group')
        assert_equal(%i[user nested/group], GlobalContext.instance.schemas.keys)
      end

      def test_file_reload
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'foo.rb'), %(schema :string))
        assert_is_a StringNode, GlobalContext.instance.schema_for('foo')
        File.write(File.join(dir, 'foo.rb'), %(schema :integer))
        assert_is_a IntegerNode, GlobalContext.instance.schema_for('foo')
      end

      def test_file_not_reloaded_in_eager
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir

        File.write(File.join(dir, 'foo.rb'), %(schema :string))

        GlobalContext.instance.eager_load!

        assert_is_a StringNode, GlobalContext.instance.schema_for('foo')
        File.write(File.join(dir, 'foo.rb'), %(schema :integer))
        assert_is_a StringNode, GlobalContext.instance.schema_for('foo')
      end

      def test_schema_not_found
        assert_nil GlobalContext.instance.schema_for('foo')
        GlobalContext.instance.eager_load!
        assert_nil GlobalContext.instance.schema_for('foo')
      end

      def test_inter_references
        schema = GlobalContext.instance.schema_for('user')

        assert schema.validate(
          first_name: 'John',
          last_name:  'Doe',
          groups:     [
            { name: 'Group 1' }
          ]
        ).valid?

        refute schema.validate(
          first_name: 'John',
          last_name:  'Doe',
          groups:     [
            { name_x: 'Group 1' }
          ]
        ).valid?

        schema = GlobalContext.instance.schema_for('nested/group')

        assert schema.validate(
          name:  'Group 1',
          users: [
            { first_name: 'John', last_name: 'Doe' }
          ]
        ).valid?

        refute schema.validate(
          name:  'Group 1',
          users: [
            { first_name_x: 'John', last_name: 'Doe' }
          ]
        ).valid?
      end

      def test_empty_schema
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'foo.rb'), %())
        assert_raises_with_message RuntimeError, /does not define any schema/ do
          GlobalContext.instance.schema_for('foo')
        end
      end

      def test_multiple_schemas
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'foo.rb'), %(schema :string\nschema :integer))
        assert_raises_with_message RuntimeError, /Schema "#{File.join(dir, 'foo.rb')}" defines multiple schemas/ do
          GlobalContext.instance.schema_for('foo')
        end
      end

      def test_invalid_schema
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'foo.rb'), %(foobarbaz))

        assert_raises_with_message RuntimeError, /Could not load schema/ do
          GlobalContext.schema_for('foo')
        end
      end

      def test_overrides_with_eager_load
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'user.rb'), %(schema :string))

        assert_raises_with_message RuntimeError, %r{in both load paths "test/schemas" and "#{dir}"} do
          GlobalContext.eager_load!
        end
      end

      def test_overrides_with_lazy_load
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'user.rb'), %(schema :string))

        assert_raises_with_message RuntimeError, %r{in both load paths "test/schemas" and "#{dir}"} do
          GlobalContext.instance.schema_for('user')
        end
      end

      def test_v3_default_options_with_lazy_load
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'test_schema.rb'), %(schema :integer))

        Schemacop.v3_default_options = { cast_str: true }.freeze

        schema = GlobalContext.instance.schema_for('test_schema')
        result = schema.validate('42')

        assert result.valid?, "Expected string '42' to be cast to integer 42, but got errors: #{result.errors}"
        assert_equal 42, result.data
      ensure
        Schemacop.v3_default_options = {}
      end

      def test_v3_default_options_with_eager_load
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'test_schema.rb'), %(schema :integer))

        Schemacop.v3_default_options = { cast_str: true }.freeze

        GlobalContext.instance.eager_load!
        schema = GlobalContext.instance.schema_for('test_schema')
        result = schema.validate('42')

        assert result.valid?, "Expected string '42' to be cast to integer 42, but got errors: #{result.errors}"
        assert_equal 42, result.data
      ensure
        Schemacop.v3_default_options = {}
      end

      def test_v3_default_options_with_nested_schema
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'form_schema.rb'), <<~SCHEMA)
          schema do
            int! :age
            str! :name
          end
        SCHEMA

        Schemacop.v3_default_options = { cast_str: true }.freeze

        schema = GlobalContext.instance.schema_for('form_schema')
        result = schema.validate({ age: '25', name: 'John' })

        assert result.valid?, "Expected string '25' to be cast to integer 25, but got errors: #{result.errors}"
        assert_equal 25, result.data[:age]
        assert_equal 'John', result.data[:name]
      ensure
        Schemacop.v3_default_options = {}
      end

      def test_v3_default_options_set_before_eager_load
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'test_schema.rb'), %(schema :integer))

        # Set default options BEFORE eager loading (simulates production mode)
        Schemacop.v3_default_options = { cast_str: true }.freeze

        GlobalContext.instance.eager_load!
        schema = GlobalContext.instance.schema_for('test_schema')
        result = schema.validate('42')

        assert result.valid?, "Expected string '42' to be cast to integer 42, but got errors: #{result.errors}"
        assert_equal 42, result.data
      ensure
        Schemacop.v3_default_options = {}
      end

      def test_v3_default_options_set_after_eager_load
        dir = Dir.mktmpdir
        Schemacop.load_paths << dir
        File.write(File.join(dir, 'test_schema.rb'), %(schema :integer))

        # Eager load schemas BEFORE setting default options
        GlobalContext.instance.eager_load!

        Schemacop.v3_default_options = { cast_str: true }.freeze

        schema = GlobalContext.instance.schema_for('test_schema')
        result = schema.validate('42')

        # NOTE: Setting v3_default_options AFTER eager loading does not work
        # because schemas are already cached. In Rails applications, the
        # Railtie initializer now runs after config/initializers (via
        # 'after: :load_config_initializers'), ensuring options are set
        # before eager loading occurs.
        #
        # This test verifies that the options don't retroactively apply.
        refute result.valid?, 'Options set after eager_load! should not affect already-loaded schemas'
        assert_equal({ [] => ['Invalid type, got type "String", expected "integer".'] }, result.errors)
      ensure
        Schemacop.v3_default_options = {}
      end
    end
  end
end
