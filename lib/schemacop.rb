# External dependencies
require 'ruby2_keywords'
require 'logger'
require 'active_support/all'
require 'set'
require 'uri'
require 'resolv'

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
    :mailbox,
    pattern: /^("\p{Print}+"\s)?<#{URI::MailTo::EMAIL_REGEXP.source[2...-2]}>$/,
    handler: ->(value) { value }
  )
  register_string_formatter(
    :boolean,
    pattern: /^(true|false|0|1)$/i,
    handler: ->(value) { %w[true 1].include?(value&.downcase) }
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
    handler: ->(value) { Integer(value, 10) }
  )

  register_string_formatter(
    :number,
    pattern: /^-?[0-9]+(\.[0-9]+)?$/,
    handler: proc do |value|
      if value.include?('.')
        Float(value)
      else
        Integer(value, 10)
      end
    end
  )

  register_string_formatter(
    :'integer-list',
    pattern: /^(-?[0-9]+)(,-?[0-9]+)*$/,
    handler: ->(value) { value.split(',').map { |i| Integer(i, 10) } }
  )

  register_string_formatter(
    :ipv4,
    pattern: Resolv::IPv4::Regex,
    handler: ->(value) { value }
  )

  register_string_formatter(
    :'ipv4-cidr',
    pattern: Regexp.new(Resolv::IPv4::Regex.source[0..-3] + %r{/([0-9]|[1-2][0-9]|3[0-2])\z}.source),
    handler: ->(value) { value }
  )

  register_string_formatter(
    :ipv6,
    pattern: Resolv::IPv6::Regex,
    handler: ->(value) { value }
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
