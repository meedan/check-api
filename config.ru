# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

if File.exist?('config/apollo-engine-proxy.json')
  port = JSON.parse(File.read('config/apollo-engine-proxy.json'))['frontends'][0]['port']
  ApolloTracing.start_proxy('config/apollo-engine-proxy.json') unless system("lsof -i:#{port}", out: '/dev/null')
end

run Rails.application
