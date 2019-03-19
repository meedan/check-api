require 'bitly'

Bitly.use_api_version_3

Bitly.configure do |config|
  config.api_version = 3
  config.access_token = CONFIG['bitly_key']
end
