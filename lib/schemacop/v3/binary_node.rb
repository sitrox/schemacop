module Schemacop
  module V3
    # Node type for binary data fields such as file uploads. Represented as
    # `{ type: 'string', format: 'binary' }` in JSON Schema / OpenAPI output.
    #
    # At runtime, validates that the value is an instance of one of the
    # configured classes (using `is_a?`).
    #
    # Default accepted classes (resolved lazily, missing classes are silently
    # skipped):
    # - `ActionDispatch::Http::UploadedFile`
    # - `Rack::Multipart::UploadedFile`
    # - `Tempfile`
    # - `String`
    #
    # @example Default usage (accepts common upload and binary types)
    #   bin! :file
    #
    # @example Restrict to specific classes
    #   bin! :file, classes: [ActionDispatch::Http::UploadedFile]
    class BinaryNode < Node
      # Classes that are always available (stdlib).
      DEFAULT_CLASSES = [Tempfile, String].freeze

      # Optional classes resolved lazily via `safe_constantize` (may not be
      # available outside of Rails/Rack).
      OPTIONAL_CLASS_NAMES = %w[
        ActionDispatch::Http::UploadedFile
        Rack::Multipart::UploadedFile
      ].freeze

      def self.allowed_options
        super + %i[classes]
      end

      def as_json
        process_json([], type: :string, format: :binary)
      end

      protected

      def init
        @classes = options.delete(:classes)
      end

      def allowed_types
        resolved_classes.to_h { |c| [c, c.name] }
      end

      def validate_self
        return unless @classes

        unless @classes.is_a?(Array)
          fail 'Option "classes" must be an array of classes.'
        end

        if @classes.empty?
          fail 'Option "classes" must not be empty.'
        end

        @classes.each do |c|
          unless c.is_a?(Class)
            fail "Option \"classes\" must contain classes, got #{c.inspect}."
          end
        end
      end

      private

      def resolved_classes
        @resolved_classes ||= @classes || (OPTIONAL_CLASS_NAMES.map(&:safe_constantize).compact + DEFAULT_CLASSES)
      end
    end
  end
end
