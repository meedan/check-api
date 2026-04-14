require 'opentelemetry/sdk'
module Check
  class OpenTelemetryConfig
    class << self
      def tracer
        @tracer ||= OpenTelemetry.tracer_provider.tracer('check-api')
      end
    end

    def configure!(resource_attributes, sampling_config: nil)
      resource_attributes ||= {}
      sampling_config ||= {}
      ENV['OTEL_RESOURCE_ATTRIBUTES'] = format_attributes(resource_attributes.merge(sampling_attributes))
      ::OpenTelemetry::SDK.configure do |c|
        c.service_name = CheckConfig.get('otel_service_name') || 'check-api'
      end
    end

    private

    def format_attributes(hash)
      return unless hash

      hash.map{ |k, v| "#{k}=#{v}"}.join(',')
    end
  end
end
