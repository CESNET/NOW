Dir["./lib/*.rb"].each { |file|
  require file
}

run Now::Application
