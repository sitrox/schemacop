# External dependencies
require 'active_support/all'
require 'set'
require 'sorbet-runtime'

# Schemacop module
module Schemacop
  CONTEXT_THREAD_KEY = :schemacop_schema_context

  mattr_accessor :load_paths
  self.load_paths = ['app/schemas']

  mattr_accessor :default_schema_version
  self.default_schema_version = 3

  def self.with_context(context)
    prev_context = Thread.current[CONTEXT_THREAD_KEY]
    Thread.current[CONTEXT_THREAD_KEY] = context
    return yield
  ensure
    Thread.current[CONTEXT_THREAD_KEY] = prev_context
  end

  def self.context
    Thread.current[CONTEXT_THREAD_KEY] ||= V3::Context.new
  end

  def self.register(*args)
    V3::NodeRegistry.register(*args)
  end
end

# Shared
require 'schemacop/scoped_env'
require 'schemacop/exceptions'

# Shared: Schemas
require 'schemacop/base_schema'
require 'schemacop/schema2'
require 'schemacop/schema3'
require 'schemacop/schema'

# Version 3 files
require 'schemacop/v3/node_registry'
require 'schemacop/v3/dsl_scope'
require 'schemacop/v3/context'
require 'schemacop/v3/global_context'
require 'schemacop/v3/result'
require 'schemacop/v3/node'
require 'schemacop/v3/combination_node'
require 'schemacop/v3/numeric_node'
require 'schemacop/v3/all_of_node'
require 'schemacop/v3/any_of_node'
require 'schemacop/v3/array_node'
require 'schemacop/v3/boolean_node'
require 'schemacop/v3/hash_node'
require 'schemacop/v3/integer_node'
require 'schemacop/v3/is_not_node'
require 'schemacop/v3/number_node'
require 'schemacop/v3/object_node'
require 'schemacop/v3/one_of_node'
require 'schemacop/v3/reference_node'
require 'schemacop/v3/string_node'
require 'schemacop/v3/symbol_node'

# Railtie
if defined?(Rails)
  require 'schemacop/railtie'
end

# Legacy version 2
require 'schemacop/v2'

# Register V3 nodes
Schemacop.register :all_of,    :all_of, Schemacop::V3::AllOfNode
Schemacop.register :any_of,    :any_of, Schemacop::V3::AnyOfNode
Schemacop.register :array,     :ary,    Schemacop::V3::ArrayNode
Schemacop.register :boolean,   :boo,    Schemacop::V3::BooleanNode
Schemacop.register :integer,   :int,    Schemacop::V3::IntegerNode
Schemacop.register :is_not,    :is_not, Schemacop::V3::IsNotNode
Schemacop.register :number,    :num,    Schemacop::V3::NumberNode
Schemacop.register :hash,      :hsh,    Schemacop::V3::HashNode
Schemacop.register :one_of,    :one_of, Schemacop::V3::OneOfNode
Schemacop.register :reference, :ref,    Schemacop::V3::ReferenceNode
Schemacop.register :object,    :obj,    Schemacop::V3::ObjectNode
Schemacop.register :string,    :str,    Schemacop::V3::StringNode
Schemacop.register :symbol,    :sym,    Schemacop::V3::SymbolNode
