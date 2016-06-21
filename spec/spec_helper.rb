require 'rspec'

Dir['./models/helpers/*.rb', './models/*.rb', './lib/*.rb'].each do |file|
  require file
end
