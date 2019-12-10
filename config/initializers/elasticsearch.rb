require 'typhoeus'
require 'typhoeus/adapters/faraday'
cloud_id = CONFIG['elasticsearch_cloud_id'].to_s
user = CONFIG['elasticsearch_cloud_id'].to_s
password = CONFIG['elasticsearch_password'].to_s
host = CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s

Elasticsearch::Persistence.client = Elasticsearch::Client.new(log: !!CONFIG['elasticsearch_log'], cloud_id: cloud_id, user: user, password: password, host: host) do |f|
  f.adapter :typhoeus
end
