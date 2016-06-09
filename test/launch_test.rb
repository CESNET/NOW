require 'test_helper'

class LaunchTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Now::Application
  end

  def test_my_default
    get '/'
    assert_equal Now::API_VERSION, last_response.body
  end

end
