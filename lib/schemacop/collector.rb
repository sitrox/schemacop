module Schemacop
  class Collector
    attr_reader :exceptions

    def initialize(data)
      @exceptions = []
      @current_path = []
      @ignore_next_segment = false
      @current_datappoint_path = [data]
      @current_index = nil
    end

    def data
      @current_datappoint_path.first
    end

    def valid?
      @exceptions.empty?
    end

    # Construct the current path
    def path(segment, index)
      ignore_this_segment = false

      previous_index = @current_index

      if @ignore_next_segment
        ignore_this_segment = true
        @ignore_next_segment = false
      else
        @current_path << segment unless ignore_this_segment
        @current_datappoint_path << @current_datappoint_path.last[index]
        @current_index = index
      end

      yield
    ensure
      @current_index = previous_index
      @current_datappoint_path.pop unless ignore_this_segment
      @current_path.pop unless ignore_this_segment
    end

    def override_value(value)
      if @current_datappoint_path.size > 1
        @current_datappoint_path[-2][@current_index] = value
      else
        @current_datappoint_path[0] = value
      end
    end

    def exception_message
      return "Schemacop validation failed:\n" + @exceptions.map do |e|
        "- #{e[:path].join('')}: #{e[:message]}"
      end.join("\n")
    end

    def error(error_msg)
      @exceptions << {
        path: @current_path.dup,
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
