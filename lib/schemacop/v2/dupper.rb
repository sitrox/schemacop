module Schemacop::V2
  class Dupper
    def self.dup_data(data)
      if data.is_a?(Hash)
        data = data.dup

        data.each do |key, value|
          data[key] = dup_data(value)
        end

        return data
      elsif data.is_a?(Array)
        return data.map { |value| dup_data(value) }
      else
        return data
      end
    end
  end
end
