require 'logger'

Dir['./models/*.rb'].each do |file|
  require file
end
require './version'
require './lib/error'
require './lib/server_cipher_auth'
require './lib/nebula'
require './lib/api'

$logger = Logger.new(STDOUT)
$logger.formatter = proc do |severity, datetime, _progname, msg|
  date_format = datetime.strftime('%Y-%m-%dT%H:%M:%S%z')
  sprintf "[#{date_format}] %5s: #{msg}\n", severity
end
$nebula = Now::Nebula.new()
