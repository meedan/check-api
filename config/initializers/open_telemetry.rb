require 'check_open_telemetry_config'

Check::OpenTelemetryConfig.new(
  CheckConfig.get('otel_exporter_otlp_endpoint'),
  CheckConfig.get('otel_exporter_otlp_headers'),
  ENV['CHECK_SKIP_HONEYCOMB']
).configure!(
  CheckConfig.get('otel_resource_attributes')
)
