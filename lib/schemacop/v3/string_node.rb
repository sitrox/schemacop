module Schemacop
  module V3
    class StringNode < Node
      ATTRIBUTES = %i[
        min_length
        max_length
        format
      ].freeze

      # rubocop:disable Layout/LineLength
      FORMAT_PATTERNS = {
        date:        /^([0-9]{4})-?(1[0-2]|0[1-9])-?(3[01]|0[1-9]|[12][0-9])$/,
        'date-time': /^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/,
        time:        /^(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/,
        email:       URI::MailTo::EMAIL_REGEXP,
        boolean:     /^(true|false|0|1)$/,
        binary:      nil,
        symbol:      nil,
        integer:     /^-?[0-9]+$/,
        number:      /^-?[0-9]+(\.[0-9]+)?$/
      }.freeze
      # rubocop:enable Layout/LineLength

      def self.allowed_options
        super + ATTRIBUTES + %i[format_options pattern allow_blank]
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
        if !value.nil?
          to_cast = value
        elsif default.present?
          to_cast = default
        else
          return nil
        end

        case options[:format]
        when :boolean
          %w[true 1].include?(to_cast)
        when :date
          return Date.parse(to_cast)
        when :'date-time'
          return DateTime.parse(to_cast)
        when :time
          Time.parse(to_cast)
        when :integer
          return Integer(to_cast)
        when :number
          return Float(to_cast)
        when :symbol
          return to_cast.to_sym
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
        if options.include?(:format) && !FORMAT_PATTERNS.include?(options[:format])
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
