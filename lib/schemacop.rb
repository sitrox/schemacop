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
    Thread.current[CONTEXT_THREAD_KEY] ||= Context.new
  end

  def self.register(*args)
    Schemacop::NodeRegistry.register(*args)
  end
end

# Shared
require 'schemacop/scoped_env'
require 'schemacop/exceptions'
require 'schemacop/schema'

# Version 3 files
require 'schemacop/node_registry'
require 'schemacop/dsl_scope'
require 'schemacop/context'
require 'schemacop/global_context'
require 'schemacop/result'
require 'schemacop/node'
require 'schemacop/combination_node'
require 'schemacop/numeric_node'
require 'schemacop/all_of_node'
require 'schemacop/any_of_node'
require 'schemacop/array_node'
require 'schemacop/boolean_node'
require 'schemacop/integer_node'
require 'schemacop/is_not_node'
require 'schemacop/number_node'
require 'schemacop/object_node'
require 'schemacop/one_of_node'
require 'schemacop/reference_node'
require 'schemacop/string_node'
require 'schemacop/symbol_node'
require 'schemacop/ruby_node'

# Railtie
if defined?(Rails)
  require 'schemacop/railtie'
end

# Legacy version 2
require 'schemacop/v2'

# Register V3 nodes
Schemacop.register :all_of,    :all_of, Schemacop::AllOfNode
Schemacop.register :any_of,    :any_of, Schemacop::AnyOfNode
Schemacop.register :array,     :ary,    Schemacop::ArrayNode
Schemacop.register :boolean,   :boo,    Schemacop::BooleanNode
Schemacop.register :integer,   :int,    Schemacop::IntegerNode
Schemacop.register :is_not,    :is_not, Schemacop::IsNotNode
Schemacop.register :number,    :num,    Schemacop::NumberNode
Schemacop.register :object,    :obj,    Schemacop::ObjectNode
Schemacop.register :one_of,    :one_of, Schemacop::OneOfNode
Schemacop.register :reference, :ref,    Schemacop::ReferenceNode
Schemacop.register :ruby,      :rby,    Schemacop::RubyNode
Schemacop.register :string,    :str,    Schemacop::StringNode
Schemacop.register :symbol,    :sym,    Schemacop::SymbolNode
