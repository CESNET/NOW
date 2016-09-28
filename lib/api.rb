require 'json'
require 'sinatra'
require 'sinatra/cross_origin'
require ::File.expand_path('../../version', __FILE__)

module Now
  # HTTP REST API of NOW (for usage by rOCCI server)
  class Application < Sinatra::Base
    attr_accessor :nebula
    register Sinatra::CrossOrigin

    def initialize
      super
      begin
        @nebula = Now::Nebula.new($config)
      rescue NowError => e
        $logger.error "[HTTP #{e.code}] #{e.message}"
      end
    end

    configure do
      enable :logging, :dump_errors
      set :raise_errors, false
    end

    configure :development do
      enable :logging, :dump_errors
      set :logging, Logger::DEBUG
      set :raise_errors, true
    end

    before do
      $logger = env['rack.logger']
    end

    helpers do
      def authz(op)
        raise NowError.new(500), 'NOW not initialized' unless nebula
        nebula.init_authz(params['user'], op)
      end
    end

    get '/' do
      cross_origin
      API_VERSION
    end

    get '/network' do
      cross_origin
      begin
        authz(Set[:get])
        networks = nebula.list_networks
        JSON.pretty_generate(networks.map(&:to_hash))
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end
    end

    post '/network' do
      cross_origin
      request.body.rewind
      begin
        begin
          netinfo = JSON.parse request.body.read
        rescue JSON::ParserError => e
          logger.error "[HTTP 400] #{e.message}"
          halt 400, e.message
        end
        # Now::Network expects Now::Range object
        if netinfo.key?('range')
          begin
            netinfo['range'] = Now::Range.from_hash(netinfo['range'])
          rescue ArgumentError => e
            logger.error "[HTTP 400] #{e.message}"
            halt 400, e.message
          end
        end
        authz(Set[:create])
        network = Now::Network.new(netinfo)
        id = nebula.create_network(network)
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end

      body id
      status 201
    end

    get '/network/:id' do
      cross_origin
      begin
        authz(Set[:get])
        network = nebula.get(params['id'])
        JSON.pretty_generate(network.to_hash)
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end
    end

    delete '/network/:id' do
      cross_origin
      begin
        authz(Set[:delete])
        nebula.delete_network(params['id'])
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end
    end

    put '/network/:id' do
      cross_origin
      request.body.rewind
      begin
        begin
          netinfo = JSON.parse request.body.read
        rescue JSON::ParserError => e
          logger.error "[HTTP 400] #{e.message}"
          halt 400, e.message
        end
        # Now::Network expects Now::Range object
        if netinfo.key?('range')
          begin
            netinfo['range'] = Now::Range.from_hash(netinfo['range'])
          rescue ArgumentError => e
            logger.error "[HTTP 400] #{e.message}"
            halt 400, e.message
          end
        end
        authz(Set[:update])
        network = Now::Network.new(netinfo)
        id = nebula.update_network(params['id'], network)
      rescue NowError => e
        logger.error "[HTTP #{e.code}] #{e.message}"
        halt e.code, e.message
      end

      body id
    end
  end
end
