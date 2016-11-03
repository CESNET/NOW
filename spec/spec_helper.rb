require 'rspec'

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  print "No coverage, simplecov not installed\n\n"
end

Dir['./models/helpers/*.rb', './models/*.rb', './lib/*.rb'].each do |file|
  require file
end

def l(name)
  fname = File.expand_path("../nebula/#{name}.xml", __FILE__)
  File.read(fname)
end

$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO

$config = {
  'network' => {
    'BRIDGE' => 'br0',
    'PHYDEV' => 'eth0',
  },
  'opennebula' => {
    'admin_password' => '012345678911234567892123456789',
    'endpoint' => 'https://localhost',
  },
  'template_dir' => ::File.expand_path('../../templates', __FILE__),
}

module Now
  class Nebula
    attr_reader :uid, :authz_vlan

    def fake_ctx(ctx)
      @ctx = ctx
    end

    def fake_authz(user, operations, vlans)
      @authz_ops = operations
      @authz_vlan = vlans
      @user = user
    end

    def one_connect(_url, _credentials)
      @ctx
    end
  end
end
