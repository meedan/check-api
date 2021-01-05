require 'typhoeus'
require 'typhoeus/adapters/faraday'

user = CheckConfig.get('elasticsearch_user').to_s
password = CheckConfig.get('elasticsearch_password').to_s
host = CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s
client = Elasticsearch::Client.new(log: !!CheckConfig.get('elasticsearch_log'), user: user, password: password, host: host) do |f|
  f.adapter :typhoeus
end

$repository = MediaSearch.new(client: client)
