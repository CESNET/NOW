module Now

  # Generic hash class with custom accessors and helper methods
  class NowHash < ::Hash
    def self.my_accessor(*keys)
      keys.each do |key|
        define_method(key) do
          return nil if !key?(key)
          fetch(key)
        end
        define_method("#{key}=") do |new_value|
          if new_value.nil?
            delete(key)
          else
            store(key, new_value)
          end
        end
      end
    end

    def initialize(parameters = {})
      parameters.select! { |_k, v| !v.nil? }
      replace(parameters)
    end

    # Conversion of the data structure to hash. Arrays and hashes are browsed, the leafs are converted by calling to_hash method or directly copied.
    # @param [Object] value Any valid value
    # @return [Hash] Returns the value in the form of hash
    def _to_hash(value)
      if value.is_a?(Array)
        value.map { |v| _to_hash(v) }
      # beware we're the Hash!!!
      elsif value.is_a?(Hash) && !value.is_a?(Now::NowHash)
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
