module Schemacop
  # {include:Schemacop::Validator.validate!}
  # @see Schemacop::Validator.validate!
  def self.validate!(schema, data)
    Validator.validate!(schema, data)
  end
end

require 'active_support/all'
require 'schemacop/exceptions'
require 'schemacop/validator'
