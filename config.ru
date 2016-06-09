require 'logger'

Dir['./models/*.rb'].each do |file|
  require file
end
require './version.rb'
require './lib/error.rb'
require './lib/nebula.rb'
require './lib/api.rb'

$logger = Logger.new(STDOUT)
$logger.formatter = proc do |severity, datetime, progname, msg|
  date_format = datetime.strftime("%Y-%m-%dT%H:%M:%S%z")
  sprintf "[#{date_format}] %5s: #{msg}\n", severity
end
$nebula = Now::Nebula.new()
run Now::Application
