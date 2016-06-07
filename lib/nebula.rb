require 'opennebula'
require 'yaml'

# http://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
public def deep_merge(second)
   merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
   self.merge(second.to_h, &merger)
end


module Now
  class Nebula
    attr_accessor :config, :logger, :client

    def load_config(file)
      begin
        c = YAML.load_file(file)
        @logger.debug "Config file '#{file}' loaded"
        return c
      rescue Errno::ENOENT
        @logger.debug "Config file '#{file}' not found"
        return {}
      end
    end

    def one_connect(url, credentials)
      @logger.debug "Connecting to #{url}..."
      @client = OpenNebula::Client.new(credentials, url)
    end

    def initialize()
      @logger = $logger
      @logger.info "Starting Network Orchestrator Wrapper (NOW #{VERSION})"
      @config = {}

      c = load_config(::File.expand_path('../../etc/now.yaml', __FILE__))
      @config = @config.deep_merge(c)
      #@logger.debug "Configuration: #{@config}"

      c = load_config('/etc/now.yaml')
      @config = @config.deep_merge(c)
      #@logger.debug "Configuration: #{@config}"

      url = @config["opennebula"]["endpoint"]
      credentials = "#{@config["opennebula"]["admin_user"]}:#{@config["opennebula"]["admin_password"]}"
      one_connect(url, credentials)
    end

    def list_networks()
      vn_pool = OpenNebula::VirtualNetworkPool.new(client, -1)
      req = vn_pool.info
      if OpenNebula.is_error?(req)
        raise NowError.new({code: 500, message: req.message})
      end

      networks = []
      vn_pool.each do |vn|
        id = vn.id
        title = vn.name
        network = Network.new({id: id, title: title})
        networks << network.to_hash
      end

      return networks
    end

  end

end
