require 'logger'

Dir['./models/*.rb'].each do |file|
  require file
end
require './version.rb'
require './lib/nebula.rb'
require './lib/api.rb'

$logger = Logger.new(STDOUT)
$nebula = Now::Nebula.new()
run Now::Application
