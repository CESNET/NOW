require 'date'

module Now

  # Network object
  class Network < NowHash
    # OpenNebula ID
    my_accessor :id

    # Network title
    my_accessor :title

    # Network summary
    my_accessor :description

    # Owner
    my_accessor :user

    # VLAN ID
    my_accessor :vlan

    # IP address range (reader)
    def range
      return nil if !key?(:range)
      fetch(:range)
    end

    # IP address range (writer)
    def range=(new_value)
      if !valid_range?(new_value)
        raise NowError.new(500), 'Invalid range type'
      end
      store(:range, new_value)
    end

    # Network state (active, inactive, error)
    my_accessor :state

    # Availability zone (cluster)
    my_accessor :zone

    def initialize(parameters = {})
      if !parameters.key?(:id)
        raise NowError.new(500), 'ID required in network object'
      end
      if parameters.key?(:range) && !valid_range?(parameters[:range])
        raise NowError.new(500), 'Valid range object required in network object'
      end
      super
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      return false if id.nil?
      return false if !valid_range?(range)
      return true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(other)
      return true if equal?(other)
      self.class == other.class &&
        id == other.id &&
        title == other.title &&
        description == other.description &&
        user == other.user &&
        vlan == other.vlan &&
        range == other.range &&
        state == other.state &&
        zone == other.zone
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(other)
      self == other
    end

    # Calculates hash code according to all attributes.
    # @return [Fixnum] Hash code
    def hash
      [id, title, description, user, vlan, range, state, zone].hash
    end

    # Returns the string representation of the object
    # @return [String] String presentation of the object
    def to_s
      to_hash.to_s
    end

    # Returns the object in the form of hash
    # @return [Hash] Returns the object in the form of hash
    def to_hash
      hash = {}
      each_pair do |attr, value|
        hash[attr] = _to_hash(value)
      end

      return hash
    end

    private

    def valid_range?(value)
      value.nil? || value.is_a?(Now::Range)
    end
  end

end
