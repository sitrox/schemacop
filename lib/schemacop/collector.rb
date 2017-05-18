module Schemacop
  class Collector
    attr_reader :current_path
    attr_reader :exceptions

    def initialize
      @exceptions = []
      @current_path = []
      @ignore_next_segment = false
    end

    def valid?
      @exceptions.empty?
    end

    # Construct the current path
    def path(segment)
      ignore_this_segment = false
      if @ignore_next_segment
        ignore_this_segment = true
        @ignore_next_segment = false
      end

      @current_path << segment unless ignore_this_segment

      yield
    ensure
      @current_path.pop unless ignore_this_segment
    end

    def exception_message
      return "Schemacop validation failed:\n" + @exceptions.map do |e|
        "- #{e[:path].join('')}: #{e[:message]}"
      end.join("\n")
    end

    def error(error_msg)
      @exceptions << {
        path: current_path.dup,
        message: error_msg
      }
    end

    # Does not include the path segment next time {Schemacop::Collector.path} is
    # called.
    #
    # @return [Schemacop::Collector]
    def ignore_next_segment
      @ignore_next_segment = true
      return self
    end
  end
end
