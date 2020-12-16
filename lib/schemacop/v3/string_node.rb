module Schemacop
  module V3
    class StringNode < Node
      ATTRIBUTES = %i[
        min_length
        max_length
        pattern
        format
        enum
      ].freeze

      # rubocop:disable Layout/LineLength
      FORMAT_PATTERNS = {
        date:        /^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])$/,
        'date-time': /^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/,
        email:       URI::MailTo::EMAIL_REGEXP,
        boolean:     /^(true|false)$/,
        binary:      nil,
        integer:     /^-?[0-9]+$/,
        number:      /^-?[0-9]+(\.[0-9]+)?$/
      }.freeze
      # rubocop:enable Layout/LineLength

      def self.allowed_options
        super + ATTRIBUTES - %i[cast_str] + %i[format_options]
      end

      def allowed_types
        { String => :string }
      end

      def as_json
        process_json(ATTRIBUTES, type: :string)
      end

      def _validate(data, result:)
        super_data = super
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
        if options[:pattern] && !super_data.match?(Regexp.compile(options[:pattern]))
          result.error "String does not match pattern #{options[:pattern].inspect}."
        end

        # Validate format #
        if options[:format] && FORMAT_PATTERNS.include?(options[:format])
          pattern = FORMAT_PATTERNS[options[:format]]
          if pattern && !super_data.match?(pattern)
            result.error "String does not match format #{options[:format].to_s.inspect}."
          elsif options[:format_options] && Node.resolve_class(options[:format])
            node = create(options[:format], **options[:format_options])
            node._validate(cast(super_data), result: result)
          end
        end
      end

      def cast(value)
        case options[:format]
        when :boolean
          return value == 'true'
        when :date
          return Date.parse(value)
        when :'date-time'
          return DateTime.parse(value)
        when :integer
          return Integer(value)
        when :number
          return Float(value)
        else
          return value || default
        end
      end

      protected

      def init
        if options.include?(:format)
          options[:format] = options[:format].to_s.dasherize.to_sym
        end
      end

      def validate_self
        if options.include?(:format) && !FORMAT_PATTERNS.include?(options[:format])
          fail "Format #{options[:format].to_s.inspect} is not supported."
        end

        if options[:min_length] && options[:max_length] && options[:min_length] > options[:max_length]
          fail 'Option "min_length" can\'t be greater than "max_length".'
        end

        if options[:pattern]
          fail 'Option "pattern" must be a string.' unless options[:pattern].is_a?(String)

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
