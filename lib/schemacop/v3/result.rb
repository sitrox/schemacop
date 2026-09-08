module Schemacop
  class Result
    attr_reader :current_path
    attr_reader :errors

    def initialize(root = nil, original_data = nil)
      @current_path = []
      @errors = {}
      @root = root
      @original_data = original_data
    end

    def valid?
      errors.empty?
    end

    def data
      if errors.any?
        return nil
      else
        return @data ||= @root.cast(@original_data)
      end
    end

    def error(message)
      @errors[current_path] ||= []
      @errors[current_path] << message
    end

    def messages_by_path
      @errors.transform_keys { |k| "/#{k.join('/')}" }
    end

    def exception_message
      messages.join("\n")
    end

    def messages(pad: 0, itemize: false)
      messages = []

      item_str = itemize ? '- ' : nil

      @errors.each do |path, path_messages|
        messages += path_messages.map do |path_message|
          pad_lines("#{item_str}/#{path.join('/')}: #{path_message}", pad)
        end
      end

      return messages
    end

    def pad_lines(string, pad = 2)
      string.split("\n").map { |line| "#{' ' * pad}#{line}" }.join("\n")
    end

    def in_path(segment)
      prev_path = @current_path
      @current_path += [sanitize_segment(segment)]
      yield
    ensure
      @current_path = prev_path
    end

    private

    # A path segment can be a key of the validated data and therefore carry any
    # encoding. Joining or splitting a message built from a string with an
    # invalid byte sequence, or from one that is incompatible with the other
    # messages, raises.
    def sanitize_segment(segment)
      return segment unless segment.is_a?(String)
      return segment if segment.valid_encoding? && Encoding.compatible?(Encoding::UTF_8, segment)

      return segment.scrub.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end
  end
end
