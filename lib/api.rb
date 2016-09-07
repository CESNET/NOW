require 'json'
require 'sinatra'
require 'sinatra/cross_origin'
require ::File.expand_path('../../version', __FILE__)

module Now
  # HTTP REST API between NOW and rOCCI server
  class Application < Sinatra::Base
    attr_accessor :nebula
    register Sinatra::CrossOrigin

    def initialize
      super
      @nebula = Now::Nebula.new($config)
    end

    configure do
      enable :logging, :dump_errors
      set :raise_errors, true
    end

    before do
      # to sinatra request logger point to proper object
      env['rack.logger'] = $logger
    end

    helpers do
      def switch_user(user)
        if user.nil?
          nebula.switch_server
        else
          nebula.switch_user(user)
        end
      end
    end

    get '/' do
      cross_origin
      API_VERSION
    end

    get '/network' do
      cross_origin
      begin
        switch_user(params['user'])
        networks = nebula.list_networks
        JSON.pretty_generate(networks.map(&:to_hash))
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end
    end

    get '/network/:id' do
      cross_origin
      begin
        switch_user(params['user'])
        network = nebula.get(params['id'])
        JSON.pretty_generate(network.to_hash)
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end
    end
  end
end
