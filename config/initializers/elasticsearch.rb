require 'typhoeus'
require 'typhoeus/adapters/faraday'

unless ENV['ELASTICSEARCH_URL'] == ""
  # NOTE: We may want to initialize explicitly with url: set for future compatibility.
  client = Elasticsearch::Client.new(log: (CheckConfig.get('elasticsearch_log').to_i == 1)) do |f|
    f.adapter :typhoeus
  end
else
  user = CheckConfig.get('elasticsearch_user').to_s
  password = CheckConfig.get('elasticsearch_password').to_s
  host = CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s
  client = Elasticsearch::Client.new(log: (CheckConfig.get('elasticsearch_log').to_i == 1), user: user, password: password, host: host) do |f|
    f.adapter :typhoeus
  end
end

$repository = MediaSearch.new(client: client)
