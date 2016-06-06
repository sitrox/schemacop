module Schemacop::Exceptions
  class Base < StandardError; end

  # This exception is thrown when the given schema definition format is invalid.
  class InvalidSchema < Base; end

  # This exception is thrown when the given data does not comply with the given
  # schema definition.
  class Validation < Base; end
end
