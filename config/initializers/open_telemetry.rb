require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

class Check::OpenTelemetry
  class << self
    def enabled?
      CheckConfig.get('otel_exporter_otlp_endpoint') && 
        CheckConfig.get('otel_exporter_otlp_headers') && 
        !ENV['CHECK_SKIP_HONEYCOMB']
    end
  end
end

if Check::OpenTelemetry.enabled?
  # Set OpenTelemetry automatic instrumentation config in environment
  # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md
  ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = CheckConfig.get('otel_exporter_otlp_endpoint')
  ENV['OTEL_EXPORTER_OTLP_HEADERS'] = CheckConfig.get('otel_exporter_otlp_headers')
  ENV['OTEL_RESOURCE_ATTRIBUTES'] = (CheckConfig.get('otel_resource_attributes') || {}).map{ |k, v| "#{k}=#{v}"}.join(',')

  # Below can be uncommented to see traces logged locally rather than reported remotely
  # ENV['OTEL_TRACES_EXPORTER'] = 'console'

  OpenTelemetry::SDK.configure do |c|
    c.service_name = CheckConfig.get('otel_service_name') || 'check-api'

    c.use 'OpenTelemetry::Instrumentation::ActiveSupport'
    c.use 'OpenTelemetry::Instrumentation::Rack'
    c.use 'OpenTelemetry::Instrumentation::ActionPack'
    c.use 'OpenTelemetry::Instrumentation::ActiveJob'
    c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
    c.use 'OpenTelemetry::Instrumentation::ActionView'
    c.use 'OpenTelemetry::Instrumentation::AwsSdk'
    c.use 'OpenTelemetry::Instrumentation::HTTP'
    c.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
    c.use 'OpenTelemetry::Instrumentation::Ethon'
    c.use 'OpenTelemetry::Instrumentation::Excon'
    c.use 'OpenTelemetry::Instrumentation::Faraday'
    c.use 'OpenTelemetry::Instrumentation::GraphQL'
    c.use 'OpenTelemetry::Instrumentation::HttpClient'
    c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
    c.use 'OpenTelemetry::Instrumentation::Rails'
    c.use 'OpenTelemetry::Instrumentation::Redis'
    c.use 'OpenTelemetry::Instrumentation::RestClient'
    c.use 'OpenTelemetry::Instrumentation::Sidekiq'
    c.use 'OpenTelemetry::Instrumentation::Sinatra'
  end
end
