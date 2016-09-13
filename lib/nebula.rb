require 'erb'
require 'opennebula'
require 'yaml'
require 'ipaddress'

module Now
  EXPIRE_LENGTH = 8 * 60 * 60

  # NOW core class for communication with OpenNebula
  class Nebula
    attr_accessor :logger, :config
    # for testing
    attr_accessor :ctx
    @ctx = nil
    @user = nil
    @server_ctx = nil
    @user_ctx = nil

    def one_connect(url, credentials)
      logger.debug "Connecting to #{url} ..."
      return OpenNebula::Client.new(credentials, url)
    end

    def switch_user(user)
      admin_user = config['opennebula']['admin_user']
      admin_password = config['opennebula']['admin_password']
      logger.debug "Authentication from #{admin_user} to #{user}"

      server_auth = ServerCipherAuth.new(admin_user, admin_password)
      expiration = Time.now.to_i + EXPIRE_LENGTH
      user_token = server_auth.login_token(expiration, user)

      @user = user
      @user_ctx = one_connect(@url, user_token)
      @ctx = @user_ctx
    end

    def switch_server
      admin_user = config['opennebula']['admin_user']
      admin_password = config['opennebula']['admin_password']
      logger.debug "Authentication to #{admin_user}"

      direct_token = "#{admin_user}:#{admin_password}"
      @user = admin_user
      @server_ctx = one_connect(@url, direct_token)
      @ctx = @server_ctx
    end

    def initialize(config)
      @logger = $logger
      logger.info "Starting Network Orchestrator Wrapper (NOW #{VERSION})"

      @config = config
      #logger.debug "[nebula] Configuration: #{config}"

      @url = config['opennebula']['endpoint']
    end

    def list_networks
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
      vn_generic = OpenNebula::VirtualNetwork.build_xml(network_id)
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)
      check(vn.info)

      network = parse_network(vn)

      return network
    end

    def create_network(netinfo)
      #logger.debug "[create_network] #{netinfo}"
      logger.info '[create_network] Network ID ignored (set by OpenNebula)' if netinfo.id
      logger.info "[create_network] Network owner ignored (will be '#{@user}')" if netinfo.user
      logger.warn '[create_network] Bridge not configured (bridge)' unless config.key? 'bridge'
      logger.warn '[create_network] Physical drvice not configured (device)' unless config.key? 'device'
      range = netinfo.range

      if range && range.address && range.address.ipv6?
        logger.warn "[create_network] Network prefix 64 for IPv6 network required (#{range.address.to_string})" unless range.address.prefix == 64
      end
      vn_generic = OpenNebula::VirtualNetwork.build_xml
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)
      b = binding
      template = ERB.new(::File.new(::File.join(config['template_dir'], 'network.erb')).read, 0, '%').result b
      template_ar = ERB.new(::File.new(::File.join(config['template_dir'], 'range.erb')).read, 0, '%').result b
      template += "\n"
      template += template_ar
      logger.debug "[create_network] template: #{template}"

      check(vn.allocate(template))
      id = vn.id.to_s
      logger.debug "[create_network] created network: #{id}"

      return id
    end

    private

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
      ip = ar && ar['NETWORK_ADDRESS'] || vn['NETWORK_ADDRESS']
      mask = ar && ar['NETWORK_MASK'] || vn['NETWORK_MASK']

      case type
      when 'IP4'
        ip = ar['IP']
        if ip.nil? || ip.empty?
          raise NowError.new(422), "Missing 'IP' in the address range #{id} of network #{vn_id}"
        end
        address = IPAddress ip
        address.prefix = 24 unless ip.include? '/'
      when 'IP6', 'IP4_6'
        ip = ar['GLOBAL_PREFIX'] || ar['ULA_PREFIX']
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

      logger.debug "[parse_range] network id=#{vn_id}, address=#{address.to_string}"
      return Now::Range.new(address: address, allocation: 'dynamic')
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
      logger.debug "[parse_network] #{vn.to_xml}"

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
        bridge: vn['BRIDGE'] || vn['TEMPLATE/BRIDGE'],
        vlan: vlan,
        range: range,
        zone: zone
      )

      return network
    end
  end
end
