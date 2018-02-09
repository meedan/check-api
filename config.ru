# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

ApolloTracing.start_proxy('config/apollo-engine-proxy.json') if File.exist?('config/apollo-engine-proxy.json')

run Rails.application
