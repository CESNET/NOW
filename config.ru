require 'logger'

require './version.rb'
require './lib/nebula.rb'
require './lib/api.rb'

$logger = Logger.new(STDOUT)
$nebula = Now::Nebula.new()
run Now::Application
