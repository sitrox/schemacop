# External dependencies
require 'ruby2_keywords'
require 'active_support/all'
require 'set'

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
end

# Load shared
require 'schemacop/scoped_env'
require 'schemacop/exceptions'
require 'schemacop/base_schema'
require 'schemacop/schema2'
require 'schemacop/schema3'
require 'schemacop/schema'

# Load individual versions
require 'schemacop/v2'
require 'schemacop/v3'

# Load Railtie
require 'schemacop/railtie' if defined?(Rails)
