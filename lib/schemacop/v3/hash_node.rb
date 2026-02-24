module Schemacop
  module V3
    class HashNode < Node
      ATTRIBUTES = %i[
        type
        min_properties
        max_properties
        dependencies
        property_names
      ].freeze

      supports_children(name: true)

      attr_reader :properties
      attr_reader :inline_refs

      def self.allowed_options
        super + ATTRIBUTES - %i[dependencies] + %i[additional_properties ignore_obsolete_properties parse_json]
      end

      def self.dsl_methods
        super + NodeRegistry.dsl_methods(true) + %i[dsl_dep dsl_add]
      end

      def add_child(node)
        if node.name.nil?
          if node.is_a?(ReferenceNode)
            @inline_refs << node
            return
          else
            fail Exceptions::InvalidSchemaError, 'Child nodes must have a name.'
          end
        end

        @properties[node.name] = node
      end

      def dsl_add(type, **options, &block)
        if @options[:additional_properties].is_a?(Node)
          fail Exceptions::InvalidSchemaError, 'You can only use "add" once to specify additional properties.'
        end

        @options[:additional_properties] = create(type, **options, &block)
      end

      def dsl_dep(source, *targets, **_kwargs)
        @options[:dependencies] ||= {}
        @options[:dependencies][source] = targets
      end

      def as_json
        properties = {}
        pattern_properties = {}

        @properties.each do |name, property|
          if name.is_a?(Regexp)
            pattern_properties[name] = property
          else
            properties[name] = property
          end
        end

        if @inline_refs.any?
          return as_json_with_inline_refs(properties, pattern_properties)
        end

        json = {}
        json[:properties] = properties.values.map { |p| [p.name, p.as_json] }.to_h if properties.any?
        json[:patternProperties] = pattern_properties.values.map { |p| [V3.sanitize_exp(p.name), p.as_json] }.to_h if pattern_properties.any?

        # In schemacop, by default, additional properties are not allowed,
        # the users explicitly need to enable additional properties
        if options[:additional_properties].is_a?(TrueClass)
          json[:additionalProperties] = true
        elsif options[:additional_properties].is_a?(Node)
          json[:additionalProperties] = options[:additional_properties].as_json
        else
          json[:additionalProperties] = false
        end

        required_properties = @properties.values.select(&:required?).map(&:name)

        if required_properties.any?
          json[:required] = required_properties
        end

        return process_json(ATTRIBUTES, json)
      end

      def allowed_types
        if options[:parse_json]
          { Hash => :object, String => :string }
        else
          { Hash => :object }
        end
      end

      def _validate(data, result: Result.new)
        super_data = super
        return if super_data.nil?

        # Handle JSON
        super_data = parse_if_json(super_data, result: result, allowed_types: { Hash => :object })
        return if super_data.nil?

        original_data_hash = super_data.dup
        data_hash = super_data.with_indifferent_access

        if original_data_hash.size != data_hash.size
          ambiguous_properties = original_data_hash.keys - data_hash.keys

          result.error "Has #{ambiguous_properties.size} ambiguous properties: #{ambiguous_properties}."
        end

        # Validate min_properties #
        if options[:min_properties] && data_hash.size < options[:min_properties]
          result.error "Has #{data_hash.size} properties but needs at least #{options[:min_properties]}."
        end

        # Validate max_properties #
        if options[:max_properties] && data_hash.size > options[:max_properties]
          result.error "Has #{data_hash.size} properties but needs at most #{options[:max_properties]}."
        end

        # Validate specified properties #
        @properties.each_value do |node|
          result.in_path(node.name) do
            next if node.name.is_a?(Regexp)

            result.error "Key #{node.name} must be given." if node.require_key? && !data_hash.include?(node.name)
            node._validate(data_hash[node.name], result: result)
          end
        end

        # Validate inline ref properties #
        inline_ref_property_names = Set.new

        @inline_refs.each do |inline_ref|
          target = inline_ref.target
          next unless target

          target.properties.each_value do |prop|
            next if prop.name.is_a?(Regexp)
            next if @properties.key?(prop.name)
            next if inline_ref_property_names.include?(prop.name)

            inline_ref_property_names << prop.name

            result.in_path(prop.name) do
              result.error "Key #{prop.name} must be given." if prop.require_key? && !data_hash.include?(prop.name)
              prop._validate(data_hash[prop.name], result: result)
            end
          end
        end

        # Validate additional properties #
        specified_properties = @properties.keys.to_set + inline_ref_property_names
        additional_properties = data_hash.reject { |k, _v| specified_properties.include?(k.to_s) }

        property_patterns = {}

        @properties.each_value do |property|
          if property.name.is_a?(Regexp)
            property_patterns[property.name] = property
          end
        end

        property_names = options[:property_names]
        property_names = Regexp.compile(property_names) if property_names

        additional_properties.each do |name, additional_property|
          if property_names && !property_names.match?(name)
            result.error "Property name #{name.inspect} does not match #{options[:property_names].inspect}."
          end

          if options[:additional_properties].is_a?(TrueClass)
            next
          elsif options[:additional_properties].is_a?(FalseClass) || options[:additional_properties].blank?
            match = property_patterns.keys.find { |p| p.match?(name.to_s) }
            if match
              result.in_path(name) do
                property_patterns[match]._validate(additional_property, result: result)
              end
            elsif (options[:ignore_obsolete_properties].is_a?(Enumerable) &&
                   options[:ignore_obsolete_properties].exclude?(name.to_sym)) ||
                  !options[:ignore_obsolete_properties]
              result.error "Obsolete property #{name.to_s.inspect}."
            end
          elsif options[:additional_properties].is_a?(Node)
            result.in_path(name) do
              options[:additional_properties]._validate(additional_property, result: result)
            end
          end
        end

        # Validate dependencies #
        options[:dependencies]&.each do |source, targets|
          targets.each do |target|
            if data_hash[source].present? && data_hash[target].blank?
              result.error "Missing property #{target.to_s.inspect} because #{source.to_s.inspect} is given."
            end
          end
        end
      end

      def children
        @properties.values + @inline_refs
      end

      def cast(data)
        data = parse_if_json(data, allowed_types: { Hash => :object })
        result = {}.with_indifferent_access
        data ||= default
        return nil if data.nil?

        data_hash = data.dup.with_indifferent_access

        property_patterns = {}
        as_names = []

        @properties.each_value do |prop|
          if prop.name.is_a?(Regexp)
            property_patterns[prop.name] = prop
            next
          end

          as_names << prop.as&.to_s if prop.as.present?

          prop_name = prop.as&.to_s || prop.name

          casted_data = prop.cast(data_hash[prop.name])

          if !casted_data.nil? || data_hash.include?(prop.name)
            result[prop_name] = casted_data
          end

          if result[prop_name].nil? && !data_hash.include?(prop.name) && !as_names.include?(prop.name)
            result.delete(prop_name)
          end
        end

        # Cast inline ref properties
        inline_ref_property_names = Set.new

        @inline_refs.each do |inline_ref|
          target = inline_ref.target
          next unless target

          target.properties.each_value do |prop|
            next if prop.name.is_a?(Regexp)
            next if @properties.key?(prop.name)
            next if inline_ref_property_names.include?(prop.name)

            inline_ref_property_names << prop.name

            prop_name = prop.as&.to_s || prop.name

            casted_data = prop.cast(data_hash[prop.name])

            if !casted_data.nil? || data_hash.include?(prop.name)
              result[prop_name] = casted_data
            end

            if result[prop_name].nil? && !data_hash.include?(prop.name)
              result.delete(prop_name)
            end
          end
        end

        # Handle regex properties
        specified_properties = @properties.keys.to_set + inline_ref_property_names
        additional_properties = data_hash.reject { |k, _v| specified_properties.include?(k.to_s.to_sym) }

        if additional_properties.any? && property_patterns.any?
          additional_properties.each do |name, additional_property|
            match_key = property_patterns.keys.find { |p| p.match?(name.to_s) }
            match = property_patterns[match_key]
            result[name] = match.cast(additional_property)
          end
        end

        # Handle additional properties
        if options[:additional_properties].is_a?(TrueClass)
          result = data_hash.merge(result)
        elsif options[:additional_properties].is_a?(Node)
          add_prop_specified = @properties.keys.to_set + inline_ref_property_names
          additional_properties = data_hash.reject { |k, _v| add_prop_specified.include?(k.to_s.to_sym) }
          if additional_properties.any?
            additional_properties_result = {}
            additional_properties.each do |key, value|
              additional_properties_result[key] = options[:additional_properties].cast(value)
            end
            result = additional_properties_result.merge(result)
          end
        end

        return result
      end

      protected

      def as_json_with_inline_refs(properties, pattern_properties)
        all_of = []

        # Add each inline ref
        @inline_refs.each do |inline_ref|
          all_of << inline_ref.as_json
        end

        # Add own properties schema if any direct properties exist
        if properties.any? || pattern_properties.any?
          own_schema = {}
          own_schema[:type] = :object
          own_schema[:properties] = properties.values.map { |p| [p.name, p.as_json] }.to_h if properties.any?
          own_schema[:patternProperties] = pattern_properties.values.map { |p| [V3.sanitize_exp(p.name), p.as_json] }.to_h if pattern_properties.any?

          if options[:additional_properties].is_a?(TrueClass)
            own_schema[:additionalProperties] = true
          elsif options[:additional_properties].is_a?(Node)
            own_schema[:additionalProperties] = options[:additional_properties].as_json
          else
            own_schema[:additionalProperties] = false
          end

          required_properties = @properties.values.select(&:required?).map(&:name)
          own_schema[:required] = required_properties if required_properties.any?

          all_of << own_schema
        end

        json = { allOf: all_of }
        return process_json(ATTRIBUTES, json)
      end

      def init
        @properties = {}
        @inline_refs = []
        @options[:type] = :object
        unless @options[:additional_properties].nil? || @options[:additional_properties].is_a?(TrueClass) || @options[:additional_properties].is_a?(FalseClass)
          fail Schemacop::Exceptions::InvalidSchemaError, 'Option "additional_properties" must be a boolean value'
        end

        # Cannot set additional_properties and ignore_obsolete_properties option to true at the same time
        if @options[:additional_properties].is_a?(TrueClass) && options[:ignore_obsolete_properties].is_a?(TrueClass)
          fail Schemacop::Exceptions::InvalidSchemaError, 'Cannot set "additional_properties" and "ignore_obsolete_properties" to true at the same time'
        end

        # Default the additional_properties option to false if it's not given
        if @options[:additional_properties].nil?
          @options[:additional_properties] = false
        end

        # Default the ignore_obsolete_properties option to false if it's not given
        if @options[:ignore_obsolete_properties].nil?
          @options[:ignore_obsolete_properties] = false
        end
      end

      def validate_self
        unless options[:min_properties].nil? || options[:min_properties].is_a?(Integer)
          fail 'Option "min_properties" must be an "integer"'
        end

        unless options[:max_properties].nil? || options[:max_properties].is_a?(Integer)
          fail 'Option "max_properties" must be an "integer"'
        end

        if @properties.values.any? { |p| p.name.is_a?(Regexp) && p.required? }
          fail 'Pattern properties can\'t be required.'
        end
      end
    end
  end
end
