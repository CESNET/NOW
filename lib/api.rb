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

    get // do
      cross_origin
      API_VERSION
    end

  end

end
