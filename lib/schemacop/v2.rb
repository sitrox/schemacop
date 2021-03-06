module Schemacop::V2
  module Exceptions
    include Schemacop::Exceptions
  end
end

require 'schemacop/v2/collector'
require 'schemacop/v2/node_resolver'
require 'schemacop/v2/node'
require 'schemacop/v2/node_with_block'
require 'schemacop/v2/node_supporting_type'
require 'schemacop/v2/field_node'
require 'schemacop/v2/node_supporting_field'
require 'schemacop/v2/caster'
require 'schemacop/v2/dupper'
require 'schemacop/v2/validator/array_validator'
require 'schemacop/v2/validator/boolean_validator'
require 'schemacop/v2/validator/hash_validator'
require 'schemacop/v2/validator/number_validator'
require 'schemacop/v2/validator/integer_validator'
require 'schemacop/v2/validator/float_validator'
require 'schemacop/v2/validator/symbol_validator'
require 'schemacop/v2/validator/string_validator'
require 'schemacop/v2/validator/nil_validator'
require 'schemacop/v2/validator/object_validator' # Matches any object, must be last validator
