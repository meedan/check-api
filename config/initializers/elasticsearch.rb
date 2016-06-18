host = CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s
Elasticsearch::Persistence.client = Elasticsearch::Client.new log: true, host: host
