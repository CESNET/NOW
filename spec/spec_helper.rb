require 'rspec'

Dir['./models/helpers/*.rb', './models/*.rb', './lib/*.rb'].each do |file|
  require file
end

def l(name)
  fname = File.expand_path("../nebula/#{name}.xml", __FILE__)
  File.read(fname)
end

$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO
