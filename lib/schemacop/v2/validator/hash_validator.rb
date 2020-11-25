module Schemacop
  module V2
    class HashValidator < NodeSupportingField
      register symbols: :hash, klasses: Hash

      option :allow_obsolete_keys

      def validate(data, collector)
        super

        if data.is_a? ActiveSupport::HashWithIndifferentAccess
          allowed_fields = @fields.keys.map { |k| k.is_a?(String) ? k.to_sym : k }
          data_keys = data.keys.map { |k| k.is_a?(String) ? k.to_sym : k }

          # If the same key is specified in the schema as string and symbol, we
          # definitely expect a Ruby hash and not one with indifferent access
          if @fields.keys.length != Set.new(allowed_fields).length
            fail Exceptions::ValidationError, 'Hash expected, but got ActiveSupport::HashWithIndifferentAccess.'
          end
        else
          allowed_fields = @fields.keys
          data_keys = data.keys
        end

        obsolete_keys = data_keys - allowed_fields

        unless option?(:allow_obsolete_keys)
          collector.error "Obsolete keys: #{obsolete_keys.inspect}." if obsolete_keys.any?
        end

        @fields.values.each do |field|
          field.validate(data, collector)
        end
      end
    end
  end
end
