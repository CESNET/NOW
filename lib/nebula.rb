require 'yaml'

module Now

  class Nebula
    attr_accessor :config, :logger

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

    def initialize()
      @logger = $logger
      @logger.info "Starting Network Orchestrator Wrapper (NOW #{VERSION})"
      @config = {}
      @config.merge! load_config(::File.expand_path('../../etc/now.yaml', __FILE__))
      @config.merge! load_config('/etc/now.yaml')
      @logger.debug "Configuration: #{@config}"
    end

  end

end
