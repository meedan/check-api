require 'typhoeus'
require 'typhoeus/adapters/faraday'
host = CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s
Elasticsearch::Persistence.client = Elasticsearch::Client.new(log: !!CONFIG['elasticsearch_log'], host: host) do |f|
  f.adapter :typhoeus
end
