module Schemacop
  class HashValidator < NodeSupportingField
    register symbols: :hash, klasses: Hash

    def validate(data, collector)
      super

      allowed_fields = @fields.keys
      obsolete_keys = data.keys - allowed_fields

      collector.error "Obsolete keys: #{obsolete_keys.inspect}." if obsolete_keys.any?

      @fields.values.each do |field|
        field.validate(data, collector)
      end
    end
  end
end
