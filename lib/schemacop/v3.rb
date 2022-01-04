module Schemacop
  module V3
    def self.register(*args)
      NodeRegistry.register(*args)
    end

    # @private
    def self.sanitize_exp(exp)
      return exp if exp.is_a?(String)

      _start_slash, caret, exp, dollar, _end_slash, flags = exp.inspect.match(%r{^(/?)(\^)?(.*?)(\$)?(/?)([ixm]*)?$}).captures
      flags = flags.chars

      if flags.delete('i')
        exp = "(?i)(#{exp})"
      end

      if flags.any?
        fail "Flags #{flags.inspect} are not supported by Schemacop."
      end

      return "#{caret}#{exp}#{dollar}"
    end
  end
end

# Require V3 files
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

# Register built-in nodes
Schemacop::V3.register :all_of,    :all_of, Schemacop::V3::AllOfNode
Schemacop::V3.register :any_of,    :any_of, Schemacop::V3::AnyOfNode
Schemacop::V3.register :array,     :ary,    Schemacop::V3::ArrayNode
Schemacop::V3.register :boolean,   :boo,    Schemacop::V3::BooleanNode
Schemacop::V3.register :integer,   :int,    Schemacop::V3::IntegerNode
Schemacop::V3.register :is_not,    :is_not, Schemacop::V3::IsNotNode
Schemacop::V3.register :number,    :num,    Schemacop::V3::NumberNode
Schemacop::V3.register :hash,      :hsh,    Schemacop::V3::HashNode
Schemacop::V3.register :one_of,    :one_of, Schemacop::V3::OneOfNode
Schemacop::V3.register :reference, :ref,    Schemacop::V3::ReferenceNode
Schemacop::V3.register :object,    :obj,    Schemacop::V3::ObjectNode
Schemacop::V3.register :string,    :str,    Schemacop::V3::StringNode
Schemacop::V3.register :symbol,    :sym,    Schemacop::V3::SymbolNode
