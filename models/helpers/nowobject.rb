module Now
  # Generic hash class with custom accessors and helper methods
  class NowObject
    def initialize(parameters = {})
      parameters.select { |_k, v| !v.nil? }.each_pair { |k, v| instance_variable_set("@#{k}", v) }
    end

    # Conversion of the data structure to hash. Arrays and hashes are browsed, the leafs are converted by calling to_hash method or directly copied.
    # @param [Object] value Any valid value
    # @return [Hash] Returns the value in the form of hash
    def _to_hash(value)
      if value.is_a?(Array)
        value.map { |v| _to_hash(v) }
      elsif value.is_a?(Hash)
        {}.tap do |hash|
          value.each { |k, v| hash[k] = _to_hash(v) }
        end
      elsif value.respond_to? :to_hash
        value.to_hash
      else
        value
      end
    end
  end
end
