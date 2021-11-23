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

  mattr_accessor :string_formatters
  self.string_formatters = {}

  mattr_accessor :v3_default_options
  self.v3_default_options = {}

  def self.register_string_formatter(name, pattern:, handler:)
    name = name.to_s.dasherize.to_sym

    string_formatters[name] = {
      pattern: pattern,
      handler: handler
    }
  end

  register_string_formatter(
    :date,
    pattern: /^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])$/,
    handler: ->(value) { Date.parse(value) }
  )

  # rubocop: disable Layout/LineLength
  register_string_formatter(
    :'date-time',
    pattern: /^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/,
    handler: ->(value) { DateTime.parse(value) }
  )
  # rubocop: enable Layout/LineLength

  register_string_formatter(
    :time,
    pattern: /^(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/,
    handler: ->(value) { Time.parse(value) }
  )

  register_string_formatter(
    :email,
    pattern: URI::MailTo::EMAIL_REGEXP,
    handler: ->(value) { value }
  )

  register_string_formatter(
    :boolean,
    pattern: /^(true|false|0|1)$/,
    handler: ->(value) { %w[true 1].include?(value) }
  )

  register_string_formatter(
    :binary,
    pattern: nil,
    handler: ->(value) { value }
  )

  register_string_formatter(
    :symbol,
    pattern: nil,
    handler: ->(value) { value.to_sym }
  )

  register_string_formatter(
    :integer,
    pattern: /^-?[0-9]+$/,
    handler: ->(value) { Integer(value) }
  )

  register_string_formatter(
    :number,
    pattern: /^-?[0-9]+(\.[0-9]+)?$/,
    handler: ->(value) { Float(value) }
  )

  register_string_formatter(
    :'integer-list',
    pattern: /^(-?[0-9]+)(,-?[0-9]+)*$/,
    handler: ->(value) { value.split(',').map(&:to_i) }
  )

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
