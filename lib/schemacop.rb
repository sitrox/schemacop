module Schemacop
  DEFAULT_CASTERS = {
    String => {
      Integer => proc { |s| Integer(s, 10) },
      Float => proc { |s| Float(s) }
    },
    Float => {
      Integer => proc { |f| Integer(f) }
    },
    Integer => {
      Float => proc { |f| Float(f) }
    }
  }
end

require 'set'
require 'active_support/core_ext/class/attribute'
require 'active_support/hash_with_indifferent_access'

require 'schemacop/scoped_env'
require 'schemacop/exceptions'
require 'schemacop/schema'
require 'schemacop/collector'
require 'schemacop/node_resolver'
require 'schemacop/node'
require 'schemacop/node_with_block'
require 'schemacop/node_supporting_type'
require 'schemacop/field_node'
require 'schemacop/root_node'
require 'schemacop/node_supporting_field'
require 'schemacop/caster'
require 'schemacop/dupper'
require 'schemacop/validator/array_validator'
require 'schemacop/validator/boolean_validator'
require 'schemacop/validator/hash_validator'
require 'schemacop/validator/number_validator'
require 'schemacop/validator/integer_validator'
require 'schemacop/validator/float_validator'
require 'schemacop/validator/symbol_validator'
require 'schemacop/validator/string_validator'
require 'schemacop/validator/nil_validator'
require 'schemacop/validator/object_validator' # Matches any object, must be last validator
