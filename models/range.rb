require 'ipaddress'

module Now
  # Address range
  class Range < NowObject
    # Address range in CIDR notation (reader)
    attr_reader :address

    # Address range in CIDR notation (writer)
    def address=(new_value)
      unless valid_address?(new_value)
        raise NowError.new(500), 'Internal error: Invalid IP network address'
      end
      @address = new_value
    end

    # Address allocation type (static, dynamic)
    attr_accessor :allocation

    # Gateway address (reader)
    attr_accessor :gateway

    # Gateway address (writer)
    def gateway=(new_value)
      unless valid_address?(new_value)
        raise NowError.new(500), 'Internal error: Invalid IP address of gateway'
      end
      @gateway = new_value
    end

    def initialize(parameters = {})
      address = parameters.key?(:address) && parameters[:address] || parameters.key?('address') && parameters['address']
      unless address
        raise NowError.new(500), 'Internal error: IP network address required'
      end
      unless valid_address?(address)
        raise NowError.new(500), 'Internal error: Invalid IP network address'
      end
      gateway = parameters.key?(:gateway) && parameters[:gateway] || parameters.key?('gateway') && parameters['gateway']
      if gateway && !valid_address?(gateway)
        raise NowError.new(500), 'Internal error: Invalid IP address of gateway'
      end
      super
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      return false unless valid_address?(address)
      return false if gateway && !valid_address?(gateway)
      return true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(other)
      return true if equal?(other)
      self.class == other.class &&
        address == other.address &&
        allocation == other.allocation &&
        gateway == other.gateway
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(other)
      self == other
    end

    # Calculates hash code according to all attributes.
    # @return [Fixnum] Hash code
    def hash
      [address, allocation, gateway].hash
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
      address.nil? || h[:address] = "#{address}/#{address.prefix}"
      allocation.nil? || h[:allocation] = allocation
      gateway.nil? || h[:gateway] = gateway.to_s

      return h
    end

    # Build the object from hash
    # @return [Now::Range] Returns the Now object of the address range
    def self.from_hash(h = {})
      p = {}

      v = (h.key?('address') && h['address']) || (h.key?(:address) && h[:address])
      p[:address] = IPAddress v if v

      v = h.key?('allocation') && h['allocation'] || h.key?(:allocation) && h[:allocation]
      p[:allocation] = v if v

      v = (h.key?('gateway') && h['gateway']) || (h.key?(:gateway) && h[:gateway])
      p[:gateway] = IPAddress v if v

      new(p)
    end

    private

    def valid_address?(value)
      !value.nil? && value.is_a?(IPAddress)
    end
  end
end
