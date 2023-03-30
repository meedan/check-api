require 'typhoeus'
require 'typhoeus/adapters/faraday'

client = Elasticsearch::Client.new(log: (CheckConfig.get('elasticsearch_log').to_i == 1)) do |f|
  f.adapter :typhoeus
end

$repository = MediaSearch.new(client: client)
