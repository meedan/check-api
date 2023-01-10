require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation'
module Check
  class OpenTelemetryConfig
    class << self
      # For configuring instrumentation the same across environments,
      # including Check::OpenTelemetryTestConfig
      def configure_instrumentation!(config)
        config.use 'OpenTelemetry::Instrumentation::ActiveSupport'
        config.use 'OpenTelemetry::Instrumentation::Rack'
        config.use 'OpenTelemetry::Instrumentation::ActionPack'
        config.use 'OpenTelemetry::Instrumentation::ActiveJob'
        config.use 'OpenTelemetry::Instrumentation::ActiveRecord'
        config.use 'OpenTelemetry::Instrumentation::ActionView'
        config.use 'OpenTelemetry::Instrumentation::AwsSdk'
        config.use 'OpenTelemetry::Instrumentation::HTTP'
        config.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
        config.use 'OpenTelemetry::Instrumentation::Ethon'
        config.use 'OpenTelemetry::Instrumentation::Excon'
        config.use 'OpenTelemetry::Instrumentation::Faraday'
        config.use 'OpenTelemetry::Instrumentation::GraphQL', schemas: [RelayOnRailsSchema]
        config.use 'OpenTelemetry::Instrumentation::HttpClient'
        config.use 'OpenTelemetry::Instrumentation::Net::HTTP'
        config.use 'OpenTelemetry::Instrumentation::PG'
        config.use 'OpenTelemetry::Instrumentation::Rails'
        config.use 'OpenTelemetry::Instrumentation::Rake'
        config.use 'OpenTelemetry::Instrumentation::RestClient'
        config.use 'OpenTelemetry::Instrumentation::Sidekiq'
        config.use 'OpenTelemetry::Instrumentation::Sinatra'
      end

      def tracer
        @tracer ||= OpenTelemetry.tracer_provider.tracer('check-api')
      end
    end

    def initialize(endpoint, headers, is_disabled = nil)
      @endpoint = endpoint
      @headers = headers
      @is_disabled = !!is_disabled
    end

    def configure!(resource_attributes, sampling_config: nil)
      resource_attributes ||= {}
      sampling_config ||= {}

      configure_exporting!
      sampling_attributes = configure_sampling!(sampling_config)

      ENV['OTEL_RESOURCE_ATTRIBUTES'] = format_attributes(resource_attributes.merge(sampling_attributes))

      ::OpenTelemetry::SDK.configure do |c|
        c.service_name = CheckConfig.get('otel_service_name') || 'check-api'

        self.class.configure_instrumentation!(c)
      end
    end

    private

    def configure_exporting!
      if exporting_disabled?
        ENV['OTEL_TRACES_EXPORTER'] = 'none'
        Rails.logger.info('[otel] Open Telemetry exporting is disabled. To change this, check app configuration')
      else
        ENV['OTEL_TRACES_EXPORTER'] = 'otlp'
        ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = @endpoint
        ENV['OTEL_EXPORTER_OTLP_HEADERS'] = @headers
        Rails.logger.info("[otel] Open Telemetry configured to export to #{@endpoint}")
      end

      # The line below can be uncommented to log traces to console rather than report them remotely
      # It will override the exporter above. Intended to be used only for debugging
      # ENV['OTEL_TRACES_EXPORTER'] = 'console'
    end

    def configure_sampling!(sampling_config)
      additional_attributes = {}
      if sampling_config[:sampler]
        ENV['OTEL_TRACES_SAMPLER'] = sampling_config[:sampler]

        begin
          rate_as_ratio = (1 / Float(sampling_config[:rate])).to_s
          additional_attributes.merge!('SampleRate' => sampling_config[:rate])
          ENV['OTEL_TRACES_SAMPLER_ARG'] = rate_as_ratio
          Rails.logger.info("[otel] Sampling traces with SampleRate #{sampling_config[:rate]} | #{rate_as_ratio}")
        rescue ArgumentError, ZeroDivisionError => e
          Rails.logger.warn("[otel] Attempt to set sampling rate for #{sampling_config[:rate]} failed with #{e}; using defaults")
        end
      else
        Rails.logger.info('[otel] Open Telemetry sampling not configured; using defaults')
      end
      additional_attributes
    end

    def exporting_disabled?
      @endpoint.blank? || @headers.blank? || @is_disabled
    end

    def format_attributes(hash)
      return unless hash

      hash.map{ |k, v| "#{k}=#{v}"}.join(',')
    end
  end
end
