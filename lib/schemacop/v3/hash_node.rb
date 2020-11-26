module Schemacop
  module V3
    class HashNode < Node
      ATTRIBUTES = %i[
        type
        min_properties
        max_properties
        dependencies
        property_names
        dependencies
      ].freeze

      supports_children(name: true)

      def self.allowed_options
        super + ATTRIBUTES - %i[dependencies] + %i[additional_properties]
      end

      def self.dsl_methods
        super + NodeRegistry.dsl_methods(true) + %i[dsl_dep dsl_add]
      end

      def add_child(node)
        unless node.name
          fail 'Child nodes must have a name.'
        end
        @properties[node.name] = node
      end

      def dsl_add(type, **options, &block)
        @options[:additional_properties] = create(type, **options, &block)
      end

      def dsl_dep(source, *targets)
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

        json = {}
        json[:properties] = Hash[properties.values.map { |p| [p.name, p.as_json] }] if properties.any?
        json[:patternProperties] = Hash[pattern_properties.values.map { |p| [sanitize_exp(p.name), p.as_json] }] if pattern_properties.any?

        if options[:additional_properties] == true
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

      def sanitize_exp(exp)
        exp = exp.to_s
        if exp.start_with?('(?-mix:')
          exp = exp.to_s.gsub(/^\(\?-mix:/, '').gsub(/\)$/, '')
        end
        return exp
      end

      def allowed_types
        { Hash => :object }
      end

      def _validate(data, result: Result.new)
        data = super
        return if data.nil?

        # Validate min_properties #
        if options[:min_properties] && data.size < options[:min_properties]
          result.error "Has #{data.size} properties but needs at least #{options[:min_properties]}."
        end

        # Validate max_properties #
        if options[:max_properties] && data.size > options[:max_properties]
          result.error "Has #{data.size} properties but needs at most #{options[:max_properties]}."
        end

        # Validate specified properties #
        @properties.values.each do |node|
          result.in_path(node.name) do
            next if node.name.is_a?(Regexp)
            node._validate(data[node.name], result: result)
          end
        end

        # Validate additional properties #
        specified_properties = @properties.keys.to_set
        additional_properties = data.reject { |k, _v| specified_properties.include?(k.to_sym) }

        property_patterns = {}

        @properties.values.each do |property|
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

          if options[:additional_properties].blank?
            match = property_patterns.keys.find { |p| p.match?(name) }
            if match
              result.in_path(name) do
                property_patterns[match]._validate(additional_property, result: result)
              end
            else
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
            if data[source].present? && data[target].blank?
              result.error "Missing property #{target.to_s.inspect} because #{source.to_s.inspect} is given."
            end
          end
        end
      end

      def children
        @properties.values
      end

      def cast(data)
        result = {}
        data ||= default
        return nil if data.nil?

        # TODO: How to handle additional keys / regex / etc.?
        @properties.values.each do |prop|
          result[prop.name] = prop.cast(data[prop.name])

          if result[prop.name].nil? && !data.include?(prop.name)
            result.delete(prop.name)
          end
        end

        return result
      end

      protected

      def init
        @properties = {}
        @options[:type] = :object
      end

      def validate_self
        if @properties.values.any? { |p| p.name.is_a?(Regexp) && p.required? }
          fail 'Pattern properties can\'t be required.'
        end
      end
    end
  end
end