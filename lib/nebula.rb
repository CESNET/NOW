require 'opennebula'
require 'yaml'

module Now

  EXPIRE_LENGTH = 8 * 60 * 60
  CONFIG_FILES = [
    ::File.expand_path('~/.config/now.yml'),
    '/etc/now.yml',
    ::File.expand_path('../../etc/now.yml', __FILE__),
  ]

  # NOW core class for communication with OpenNebula
  class Nebula
    attr_accessor :logger
    @ctx = nil
    @server_ctx = nil
    @user_ctx = nil

    def load_config(file)
      c = YAML.load_file(file)
      logger.debug "Config file '#{file}' loaded"
      return c
    rescue Errno::ENOENT
      logger.debug "Config file '#{file}' not found"
      return {}
    end

    def one_connect(url, credentials)
      logger.debug "Connecting to #{url} ..."
      return OpenNebula::Client.new(credentials, url)
    end

    def switch_user(user)
      admin_user = @config['opennebula']['admin_user']
      admin_password = @config['opennebula']['admin_password']
      logger.debug "Authentication from #{admin_user} to #{user}"

      server_auth = ServerCipherAuth.new(admin_user, admin_password)
      expiration = Time.now.to_i + EXPIRE_LENGTH
      user_token = server_auth.login_token(expiration, user)

      @user_ctx = one_connect(@url, user_token)
      @ctx = @user_ctx
    end

    def switch_server()
      admin_user = @config['opennebula']['admin_user']
      admin_password = @config['opennebula']['admin_password']
      logger.debug "Authentication to #{admin_user}"

      direct_token = "#{admin_user}:#{admin_password}"
      @server_ctx = one_connect(@url, direct_token)
      @ctx = @server_ctx
    end

    def initialize()
      @logger = $logger
      logger.info "Starting Network Orchestrator Wrapper (NOW #{VERSION})"
      @config = {}

      CONFIG_FILES.each do |path|
        if ::File.exist?(path)
          @config = load_config(path)
          break
        end
      end
      logger.debug "Configuration: #{@config}"

      @url = @config['opennebula']['endpoint']
    end

    def list_networks()
      vn_pool = OpenNebula::VirtualNetworkPool.new(@ctx, -1)
      check(vn_pool.info)

      networks = []
      vn_pool.each do |vn|
        id = vn.id
        title = vn.name
        network = Network.new(id: id, title: title)
        networks << network.to_hash
      end

      return networks
    end

    def get(network_id)
      vn_generic = OpenNebula::VirtualNetwork.build_xml(network_id)
      vn = OpenNebula::VirtualNetwork.new(vn_generic, @ctx)
      check(vn.info)

      id = vn.id
      title = vn.name
      logger.debug "OpenNebula get(#{network_id}) ==> #{id}, #{title}"
      network = Network.new(id: id, title: title)

      return network.to_hash
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
      if !OpenNebula.is_error?(return_code)
        return true
      end

      code = error_one2http(return_code.errno)
      raise NowError.new(code), return_code.message
    end

  end
end
