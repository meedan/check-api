require 'check_open_telemetry_config'
require 'check_open_telemetry_test_config'

# Lines immediately below set any environment config that should 
# be applied to all environments
ENV['OTEL_LOG_LEVEL'] = CheckConfig.get('otel_log_level')

unless Rails.env.test?
  Check::OpenTelemetryConfig.new(
    CheckConfig.get('otel_exporter_otlp_endpoint'),
    CheckConfig.get('otel_exporter_otlp_headers'),
    ENV['CHECK_SKIP_HONEYCOMB']
  ).configure!(
    CheckConfig.get('otel_resource_attributes')
  )
else
  Check::OpenTelemetryTestConfig.configure!
end
