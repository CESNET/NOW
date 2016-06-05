require 'sinatra'
require 'sinatra/cross_origin'

module Now

  class Application < Sinatra::Base
    register Sinatra::CrossOrigin
    attr_accessor :api_version

    def initialize
      super
      @api_version = '0.0.0'
    end

    get // do
      cross_origin
      @api_version
    end

  end

end
