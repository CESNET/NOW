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
      @nebula = $nebula
    end

    configure do
      enable :logging, :dump_errors
      set :raise_errors, true
    end

    before do
      # to sinatra request logger point to proper object
      env['rack.logger'] = $logger
    end

    get '/' do
      cross_origin
      API_VERSION
    end

    get '/list' do
      cross_origin
      begin
        networks = @nebula.list_networks
        JSON.pretty_generate(networks)
      rescue NowError => e
        halt e.code, e.message
      end
    end

    get '/network/:id' do
      cross_origin
      begin
        network = @nebula.get(params['id'])
        JSON.pretty_generate(network)
      rescue NowError => e
        halt e.code, e.message
      end
    end

  end
end
