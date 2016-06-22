require 'ipaddress'

module Now

  # Address range
  class Range < NowObject

    # Address range in CIDR notation (reader)
    attr_reader :address

    # Address range in CIDR notation (writer)
    def address=(new_value)
      if !valid_address?(new_value)
        raise NowError.new(500), 'Internal error: Invalid IP network address'
      end
      @address = new_value
    end

    # Address allocation type (static, dynamic)
    attr_accessor :allocation

    def initialize(parameters = {})
      if !parameters.key?(:address)
        raise NowError.new(500), 'Internal error: IP network address required'
      end
      if !valid_address?(parameters[:address])
        raise NowError.new(500), 'Internal error: Invalid IP network address'
      end
      super
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      return false if !valid_address?(address)
      return true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(other)
      return true if equal?(other)
      self.class == other.class &&
        address == other.address &&
        allocation == other.allocation
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(other)
      self == other
    end

    # Calculates hash code according to all attributes.
    # @return [Fixnum] Hash code
    def hash
      [address, allocation].hash
    end

    # Returns the string representation of the object
    # @return [String] String presentation of the object
    def to_s
      to_hash.to_s
    end

    # Returns the object in the form of hash
    # @return [Hash] Returns the object in the form of hash
    def to_hash
      h = {}
      if !address.nil?
        h[:address] = "#{address}/#{address.prefix}"
      end
      if !allocation.nil?
        h[:allocation] = allocation
      end

      return h
    end

    private

    def valid_address?(value)
      !value.nil? && value.is_a?(IPAddress)
    end

  end

end
