require 'json'
require 'sinatra'
require 'sinatra/cross_origin'
require ::File.expand_path('../../version',  __FILE__)

module Now

  class Application < Sinatra::Base
    attr_accessor :nebula
    register Sinatra::CrossOrigin

    def initialize
      super
      @nebula = $nebula
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
  end

end
