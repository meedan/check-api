require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

module Check
  class OpenTelemetryConfig
    ENV_CONFIG = %w(OTEL_TRACES_EXPORTER OTEL_EXPORTER_OTLP_ENDPOINT OTEL_EXPORTER_OTLP_HEADERS OTEL_RESOURCE_ATTRIBUTES)

    def initialize(endpoint, headers, is_disabled = nil)
      @endpoint = endpoint
      @headers = headers
      @is_disabled = !!is_disabled
    end

    def configure!(resource_attributes)
      if exporting_disabled?
        ENV['OTEL_TRACES_EXPORTER'] = 'none'
        Rails.logger.info(message: '[otel] Open Telemetry exporting is disabled. To change this, set both otel_exporter_otlp_endpoint and otel_exporter_otlp_headers in config')
      else
        ENV['OTEL_TRACES_EXPORTER'] = 'otlp'
        ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = @endpoint
        ENV['OTEL_EXPORTER_OTLP_HEADERS'] = @headers
      end
      ENV['OTEL_RESOURCE_ATTRIBUTES'] = format_attributes(resource_attributes)

      # The line below can be uncommented to log traces to console rather than report them remotely
      # It will override the exporter above. Intended to be used only for debugging
      # ENV['OTEL_TRACES_EXPORTER'] = 'console'

      ::OpenTelemetry::SDK.configure do |c|
        c.service_name = CheckConfig.get('otel_service_name') || 'check-api'

        # Keep this in sync with test_helper, to make sure we track
        # any potential issues coming from instrumentation libraries
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
        c.use 'OpenTelemetry::Instrumentation::PG'
        c.use 'OpenTelemetry::Instrumentation::Rails'
        c.use 'OpenTelemetry::Instrumentation::Redis'
        c.use 'OpenTelemetry::Instrumentation::RestClient'
        c.use 'OpenTelemetry::Instrumentation::Sidekiq'
        c.use 'OpenTelemetry::Instrumentation::Sinatra'
      end
    end

    private

    def exporting_disabled?
      @endpoint.blank? || @headers.blank? || @is_disabled
    end

    def format_attributes(hash)
      return unless hash

      hash.map{ |k, v| "#{k}=#{v}"}.join(',')
    end
  end
end
