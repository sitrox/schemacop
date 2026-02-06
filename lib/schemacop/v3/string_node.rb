module Schemacop
  module V3
    class StringNode < Node
      ATTRIBUTES = %i[
        min_length
        max_length
        format
      ].freeze

      def self.allowed_options
        super + ATTRIBUTES + %i[format_options pattern allow_blank encoding]
      end

      def allowed_types
        { String => :string }
      end

      def as_json
        json = { type: :string }
        if options[:pattern]
          json[:pattern] = V3.sanitize_exp(Regexp.compile(options[:pattern]))
        end
        process_json(ATTRIBUTES, json)
      end

      def _validate(data, result:)
        super_data = super

        # Validate blank #
        if options[:allow_blank].is_a?(FalseClass) && super_data.blank?
          result.error 'String is blank but must not be blank!'
        end

        return if super_data.nil?

        # Validate length #
        length = super_data.size

        if options[:min_length] && length < options[:min_length]
          result.error "String is #{length} characters long but must be at least #{options[:min_length]}."
        end

        if options[:max_length] && length > options[:max_length]
          result.error "String is #{length} characters long but must be at most #{options[:max_length]}."
        end

        # Validate pattern #
        if (pattern = options[:pattern])
          unless options[:pattern].is_a?(Regexp)
            pattern = Regexp.compile(pattern)
          end

          unless super_data.match?(pattern)
            result.error "String does not match pattern #{V3.sanitize_exp(pattern).inspect}."
          end
        end

        # Validate encoding matches #
        if options[:encoding]
          allowed_encodings = Array(options[:encoding])
          unless allowed_encodings.include?(super_data.encoding.name)
            result.error "String has encoding #{super_data.encoding.name.inspect} but must be #{allowed_encodings.map(&:inspect).join(' or ')}."
          end
        end

        # Validate encoding #
        unless super_data.valid_encoding?
          result.error "String has invalid #{super_data.encoding.name.inspect} encoding."
        end

        # Validate format #
        if options[:format] && Schemacop.string_formatters.include?(options[:format])
          pattern = Schemacop.string_formatters[options[:format]][:pattern]

          if pattern && !super_data.match?(pattern)
            result.error "String does not match format #{options[:format].to_s.inspect}."
          elsif options[:format_options] && Node.resolve_class(options[:format])
            node = create(options[:format], **options[:format_options])
            node._validate(cast(super_data), result: result)
          end
        end
      end

      def cast(value)
        if !value.nil?
          to_cast = value
        elsif default.present?
          to_cast = default
        else
          return nil
        end

        if (handler = Schemacop.string_formatters.dig(options[:format], :handler))
          return handler.call(to_cast)
        else
          return to_cast
        end
      end

      protected

      def init
        if options.include?(:format)
          options[:format] = options[:format].to_s.dasherize.to_sym
        end
      end

      def validate_self
        if options.include?(:format) && !Schemacop.string_formatters.include?(options[:format])
          fail "Format #{options[:format].to_s.inspect} is not supported."
        end

        unless options[:min_length].nil? || options[:min_length].is_a?(Integer)
          fail 'Option "min_length" must be an "integer"'
        end

        unless options[:max_length].nil? || options[:max_length].is_a?(Integer)
          fail 'Option "max_length" must be an "integer"'
        end

        if options[:min_length] && options[:max_length] && options[:min_length] > options[:max_length]
          fail 'Option "min_length" can\'t be greater than "max_length".'
        end

        if options[:encoding]
          unless options[:encoding].is_a?(String) || (options[:encoding].is_a?(Array) && options[:encoding].all? { |e| e.is_a?(String) })
            fail 'Option "encoding" must be a string or an array of strings.'
          end

          Array(options[:encoding]).each do |encoding|
            begin
              Encoding.find(encoding)
            rescue ArgumentError
              fail "Option \"encoding\" contains unknown encoding #{encoding.inspect}."
            end
          end
        end

        if options[:pattern]
          unless options[:pattern].is_a?(String) || options[:pattern].is_a?(Regexp)
            fail 'Option "pattern" must be a string or Regexp.'
          end

          begin
            Regexp.compile(options[:pattern])
          rescue RegexpError => e
            fail "Option \"pattern\" can't be parsed: #{e.message}."
          end
        end
      end
    end
  end
end
