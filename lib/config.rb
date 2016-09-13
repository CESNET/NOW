require 'logger'
require 'yaml'

module Now
  CONFIG_FILES = [
    ::File.expand_path('~/.config/now.yml'),
    '/etc/now.yml',
    ::File.expand_path('../../etc/now.yml', __FILE__),
  ].freeze

  # Config class for NOW
  class Config < Hash
    attr_accessor :logger

    def load_config(file)
      c = YAML.load_file(file)
      logger.debug "Config file '#{file}' loaded"
      return c
    rescue Errno::ENOENT
      logger.debug "Config file '#{file}' not found"
      return {}
    end

    def initialize
      @logger = $logger
      config = {}

      CONFIG_FILES.each do |path|
        if ::File.exist?(path)
          config = load_config(path)
          break
        end
      end
      config['template_dir'] = ::File.expand_path('../../templates', __FILE__)
      #logger.debug "[config] Configuration: #{config}"

      replace config
    end
  end
end
