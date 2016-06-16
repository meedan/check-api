host = CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s
log = Rails.env.production?
Elasticsearch::Persistence.client = Elasticsearch::Client.new log: log, host: host
