# External dependencies
require 'active_support/all'
require 'set'
require 'sorbet-runtime'

# Schemacop module
module Schemacop
  CONTEXT_THREAD_KEY = :schemacop_schema_context

  mattr_accessor :load_paths
  self.load_paths = ['app/schemas']

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
end

# Shared
require 'schemacop/scoped_env'
require 'schemacop/exceptions'

# Version 3 files
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
