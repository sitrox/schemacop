module Schemacop
  class Collector
    attr_reader :current_path

    def initialize
      @exceptions = []
      @current_path = []
    end

    def valid?
      @exceptions.empty?
    end

    def path(segment)
      @current_path << segment
      yield
    ensure
      @current_path.pop
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
  end
end
