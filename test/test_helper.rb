require './application'
require 'minitest/autorun'
require 'rack/test'

class LunchTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Now::Application
  end

  def test_my_default
    get '/'
    assert_equal Now::API_VERSION, last_response.body
  end

end
