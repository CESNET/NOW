require 'erb'
require 'opennebula'
require 'yaml'
require 'ipaddress'

module Now
  EXPIRE_LENGTH = 8 * 60 * 60

  # NOW core class for communication with OpenNebula
  class Nebula
    attr_accessor :logger, :config
    @authz = nil
    @authz_vlan = nil
    @ctx = nil
    @user = nil

    def one_connect(url, credentials)
      logger.debug "Connecting to #{url} ..."
      return OpenNebula::Client.new(credentials, url)
    end

    # Connect to OpenNebula as given user
    #
    # There are two modes:
    #
    # 1) admin_user with server_cipher driver is required and any user must be specified
    #
    # 2) admin_user with regular password is required and user may not be specified,
    #    impersonation is not possible, so admin_user must have enough rights to read everything
    #
    # In multi-user environment choice 1) with impersonation is needed.
    #
    # @param user [String] user name (nil for direct login as admin_user)
    def switch_user(user)
      admin_user = config['opennebula']['admin_user']
      admin_password = config['opennebula']['admin_password']

      if user
        logger.debug "Authentication from #{admin_user} to #{user}"

        server_auth = ServerCipherAuth.new(admin_user, admin_password)
        expiration = Time.now.to_i + EXPIRE_LENGTH
        user_token = server_auth.login_token(expiration, user)

        @user = user
        @ctx = one_connect(@url, user_token)
      else
        logger.debug "Authentication to #{admin_user}"

        direct_token = "#{admin_user}:#{admin_password}"
        @user = admin_user
        @ctx = one_connect(@url, direct_token)
      end
    end

    def initialize(config)
      @logger = $logger
      logger.info "Starting Network Orchestrator Wrapper (NOW #{VERSION})"

      @config = config
      #logger.debug "[nebula] Configuration: #{config}"

      @url = config['opennebula']['endpoint']
    end

    # Fetch data needed for authorization decisions and connect to OpenNebula
    # under specified user.
    #
    # @param user [String] user name (nil for direct login as admin_user)
    # @param operations [Set] planned operations: :create, :update, :delete, :get
    def init_authz(user, operations)
      # only create and update operation needs to fetch information about networks
      enable_authz = !(Set[:create, :update] & operations).empty?

      if enable_authz
        logger.debug "[#{__method__}] extended authorization needed, data will be fetched"

        # impersonation not possible when using direct login
        super_user = (config['opennebula']['super_user'] if user)
        switch_user(super_user)

        @authz = Set[:get]
        @authz_vlan = {}
        list_networks.each do |n|
          # VLAN explicitly as string to reliable compare
          @authz_vlan[n.vlan.to_s] = n.user if n.vlan
        end
        logger.debug "[#{__method__}] scanned VLANs: #{@authz_vlan}"
      else
        logger.debug "[#{__method__}] extended authorization not needed for #{op2str operations}"
      end

      switch_user(user) if user || !enable_authz
      @authz = operations
    end

    def list_networks
      authz(Set[:get], nil)
      vn_pool = OpenNebula::VirtualNetworkPool.new(@ctx, -1)
      check(vn_pool.info)

      networks = []
      vn_pool.each do |vn|
        begin
          network = parse_network(vn)
          networks << network
        rescue NowError => e
          logger.warn "[code #{e.code}] #{e.message}, skipping"
        end
      end

      return networks
    end

    def get(network_id)
      authz(Set[:get], nil)
      vn_generic = OpenNebula::VirtualNetwork.build_xml(network_id)
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)
      check(vn.info)

      network = parse_network(vn)

      return network
    end

    def create_network(netinfo)
      authz(Set[:create], netinfo)
      #logger.debug "[create_network] #{netinfo}"
      logger.info "[#{__method__}] Network ID ignored (set by OpenNebula)" if netinfo.id
      logger.info "[#{__method__}] Network owner ignored (will be '#{@user}')" if netinfo.user
      logger.warn "[#{__method__}] Bridge not configured (BRIDGE)" unless config.key?('network') && config['network'].key?('BRIDGE')
      logger.warn "[#{__method__}] Physical device not configured (PHYDEV)" unless config.key?('network') && config['network'].key?('PHYDEV')
      range = netinfo.range

      if range && range.address && range.address.ipv6?
        logger.warn "[#{__method__}] Network prefix 64 for IPv6 network required (#{range.address.to_string})" unless range.address.prefix == 64
      end
      vn_generic = OpenNebula::VirtualNetwork.build_xml
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)

      template = raw2template_network(netinfo, {}, nil) + "\n" + raw2template_range(netinfo.range, {})
      logger.debug "[#{__method__}] template: #{template}"

      check(vn.allocate(template))
      id = vn.id.to_s
      logger.info "[#{__method__}] created network: #{id}"

      return id
    end

    def delete_network(network_id)
      authz(Set[:delete], nil)
      vn_generic = OpenNebula::VirtualNetwork.build_xml(network_id)
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)
      check(vn.delete)
      logger.info "[delete_network] deleted network: #{network_id}"
    end

    # Update OpenNebula network
    #
    # Only name and address range can be modified by regular users.
    #
    # All NOW-managed networks already has address range. If not, update will try to add it, but
    # that requires ADMIN NET privilege.
    #
    # @param network_id [String] OpenNebula network ID
    # @param netinfo [Now::Network] sparse network structure with attributes to modify
    def update_network(network_id, netinfo)
      authz(Set[:update], netinfo)
      #logger.debug "[#{__method__}] #{netinfo}"
      logger.info "[#{__method__}] Network ID ignored (got from URL)" if netinfo.id
      logger.info "[#{__method__}] Network owner ignored (change not implemented)" if netinfo.user

      vn_generic = OpenNebula::VirtualNetwork.build_xml(network_id)
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)
      check(vn.info)

      if netinfo.title
        logger.info "[#{__method__}] renaming network #{network_id} to '#{netinfo.title}'"
        check(vn.rename(netinfo.title))
      end

      range = netinfo.range
      if range
        ar_id = nil
        vn.each('AR_POOL/AR') do |ar|
          ar_id = ar['AR_ID']
          break
        end
        if ar_id
          template = raw2template_range(range, 'AR_ID' => ar_id)
          logger.debug "[#{__method__}] address range template: #{template}"
          logger.info "[#{__method__}] updating address range #{ar_id} in network #{network_id}"
          check(vn.update_ar(template))
        else
          # try to add address range if none found (should not happen with NOW-managed networks),
          # but that requires ADMIN NET privileges in OpenNebula
          template = raw2template_range(range, {})
          logger.debug "[#{__method__}] address range template: #{template}"
          logger.info "[#{__method__}] adding address range to network #{network_id}"
          check(vn.add_ar(template))
        end
      end

      # change also all non-OpenNebula attributes inside network template
      template = raw2template_network(netinfo, {}, vn)
      logger.debug "[#{__method__}] append template: #{template}"

      check(vn.update(template, true))
      id = vn.id.to_s
      logger.info "[#{__method__}] updated network: #{id}"

      return id
    end

    private

    # Check authorization
    #
    # Raised error if not passed.
    #
    # Most of the authorization is up to OpenNebula. NOW component only check
    # if one user doesn't use other users' VLAN ID.
    #
    # @param operations [Set] operations to perform (:get, :create, :modify, :delete)
    # @param network [Now::Network] network (for :create and :modify)
    def authz(operations, network)
      if network && network.vlan
        logger.debug "[#{__method__}] checking VLAN #{network.vlan}, operations #{op2str operations}"
      else
        logger.debug "[#{__method__}] checking operations #{op2str operations}"
      end
      raise NowError.new(500), 'NOW authorization not initialized' unless @authz

      missing = operations - @authz
      raise NowError.new(500), "NOW authorization not enabled for operations #{op2str missing}" unless missing.empty?

      operations &= Set[:create, :update]
      if !operations.empty? && network.vlan
        # VLAN explicitly as string to reliable compare
        network.vlan = network.vlan.to_s
        if @authz_vlan.key?(network.vlan)
          owner = @authz_vlan[network.vlan]
          logger.debug "[#{__method__}] for VLAN #{network.vlan} found owner #{owner}"
          raise NowError.new(403), "#{@user} not authorized to use VLAN #{network.vlan} for operations #{op2str operations}" if owner != @user
        else
          logger.debug "[#{__method__}] VLAN #{network.vlan} is free"
        end
      end
    end

    def op2str(operations)
      if operations
        operations.to_a.sort.join ', '
      else
        '(none)'
      end
    end

    def error_one2http(errno)
      case errno
      when OpenNebula::Error::ESUCCESS
        return 200
      when OpenNebula::Error::EAUTHENTICATION
        return 401
      when OpenNebula::Error::EAUTHORIZATION
        return 403
      when OpenNebula::Error::ENO_EXISTS
        return 404
      when OpenNebula::Error::EXML_RPC_API
        return 500
      when OpenNebula::Error::EACTION
        return 400
      when OpenNebula::Error::EINTERNAL
        return 500
      when OpenNebula::Error::ENOTDEFINED
        return 501
      else
        return 500
      end
    end

    def check(return_code)
      return true unless OpenNebula.is_error?(return_code)

      code = error_one2http(return_code.errno)
      raise NowError.new(code), return_code.message
    end

    def parse_range(vn_id, vn, ar)
      id = ar && ar['AR_ID'] || '(undef)'
      type = ar && ar['TYPE']
      gateway = ar && ar['GATEWAY']
      gateway = vn['TEMPLATE/GATEWAY'] if !gateway || gateway.empty?
      ip = ar && ar['NETWORK_ADDRESS']
      ip = vn['TEMPLATE/NETWORK_ADDRESS'] if !ip || ip.empty?
      mask = ar && ar['NETWORK_MASK']
      mask = vn['TEMPLATE/NETWORK_MASK'] if !mask || mask.empty?

      case type
      when 'IP4'
        ip = ar['IP']
        if ip.nil? || ip.empty?
          raise NowError.new(422), "Missing 'IP' in the address range #{id} of network #{vn_id}"
        end
        address = IPAddress ip
        address.prefix = 24 unless ip.include? '/'
      when 'IP6', 'IP4_6'
        ip = ar['GLOBAL_PREFIX']
        ip = ar['ULA_PREFIX'] if !ip || ip.empty?
        if ip.nil? || ip.empty?
          raise NowError.new(422), "Missing 'GLOBAL_PREFIX' in the address range #{id} of network #{vn_id}"
        end
        address = IPAddress ip
        address.prefix = 64 unless ip.include? '/'
      when nil
        if ip.nil? || ip.empty?
          raise NowError.new(422), "No address range and no NETWORK_ADDRESS in the network #{vn_id}"
        end
        address = IPAddress ip
      else
        raise NowError.new(501), "Unknown type '#{type}' in the address range #{id} of network #{vn_id}"
      end

      # get the mask from NETWORK_MASK network parameter, if IP not in CIDR notation already
      unless ip.include? '/'
        if mask && !mask.empty?
          if /\d+\.\d+\.\d+\.\d+/ =~ mask
            address.netmask = mask
          else
            address.prefix = mask.to_i
          end
        end
      end

      gateway = IPAddress gateway if gateway

      if gateway
        logger.debug "[#{__method__}] network id=#{vn_id}, address=#{address.to_string}, gateway=#{gateway}"
      else
        logger.debug "[#{__method__}] network id=#{vn_id}, address=#{address.to_string}"
      end
      return Now::Range.new(address: address, allocation: 'dynamic', gateway: gateway)
    end

    def parse_ranges(vn_id, vn)
      ar = nil
      vn.each('AR_POOL/AR') do |a|
        unless ar.nil?
          raise NowError.new(501), "Multiple address ranges found in network #{vn_id}"
        end
        ar = a
      end
      range = parse_range(vn_id, vn, ar)
      return range
    end

    def parse_cluster(vn_id, vn)
      cluster = nil
      vn.each('CLUSTERS/ID') do |cluster_xml|
        id = cluster_xml.text
        logger.debug "[parse_cluster] cluster: #{id}"
        unless cluster.nil?
          raise NowError.new(501), "Multiple clusters assigned to network #{vn_id}"
        end
        cluster = id
      end
      return cluster
    end

    def parse_network(vn)
      #logger.debug "[#{__method__}] #{vn.to_xml}"

      id = vn.id
      title = vn.name
      desc = vn['DESCRIPTION'] || vn['TEMPLATE/DESCRIPTION']
      desc && desc.empty? && desc = nil
      vlan = vn['VLAN_ID'] || vn['TEMPLATE/VLAN_ID']
      vlan && vlan.empty? && vlan = nil

      range = parse_ranges(id, vn)
      zone = parse_cluster(id, vn)
      network = Network.new(
        id: id,
        title: title,
        description: desc,
        user: vn['UNAME'],
        vlan: vlan,
        range: range,
        zone: zone
      )
      logger.debug "[#{__method__}] #{network}"

      return network
    end

    def raw2template_network(netinfo, attributes, old_vn)
      range = netinfo.range

      attributes.merge!(config['network']) if config.key? 'network'
      attributes['NAME'] = netinfo.title if netinfo.title
      attributes['DESCRIPTION'] = netinfo.description if netinfo.description
      attributes['CLUSTERS'] = netinfo.zone if netinfo.zone
      attributes['VLAN_ID'] = netinfo.vlan if netinfo.vlan
      attributes['VN_MAD'] = 'vxlan'
      if range
        address = range.address
        attributes['GATEWAY'] = range.gateway if range.gateway && address.ipv4?
        attributes['GATEWAY6'] = range.gateway if range.gateway && address.ipv6?
        attributes['NETWORK_ADDRESS'] = address.network.to_s
        attributes['NETWORK_MASK'] = address.netmask if address.ipv4?
        attributes['NETWORK_MASK'] = address.prefix if address.ipv6?
      end

      if old_vn
        attributes.keys.each do |key|
          if old_vn.has_elements?(key)
            logger.debug "[#{__method__}] removing internal attribute #{key}"
            attributes.delete(key)
          end
        end
      end

      b = binding
      ERB.new(::File.new(::File.join(config['template_dir'], 'network.erb')).read, 0, '%').result b
    end

    def raw2template_range(range, rattributes)
      return nil unless range

      if range.address.ipv4?
        rattributes['TYPE'] = 'IP4'
        rattributes['IP'] = range.address.to_s
        rattributes['SIZE'] = range.address.size - 2
      end
      if range.address.ipv6?
        rattributes['TYPE'] = 'IP6'
        if IPAddress('fc00::/7').include? range.address
          rattributes['ULA_PREFIX'] = range.address.network.to_s
        else
          rattributes['GLOBAL_PREFIX'] = range.address.network.to_s
        end
        rattributes['SIZE'] = range.address.size >= 2**31 ? 2**31 : range.address.size - 2
      end

      b = binding
      ERB.new(::File.new(::File.join(config['template_dir'], 'range.erb')).read, 0, '%').result b
    end
  end
end
