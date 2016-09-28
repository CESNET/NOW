require 'logger'

Dir['./models/helpers/*.rb', './models/*.rb'].each do |file|
  require file
end
require './version'
require './lib/error'
require './lib/server_cipher_auth'
require './lib/config'
require './lib/nebula'
require './lib/api'

# initial application logger, switched to rack.logger later
$logger = Logger.new(STDOUT)
$logger.formatter = proc do |_severity, _datetime, _progname, msg|
  format("#{msg}\n")
end
$config = Now::Config.new
