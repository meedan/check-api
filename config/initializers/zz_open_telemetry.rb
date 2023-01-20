require 'check_open_telemetry_config'
require 'check_open_telemetry_test_config'

# Lines immediately below set any environment config that should
# be applied to all environments
ENV['OTEL_LOG_LEVEL'] = CheckConfig.get('otel_log_level')

unless Rails.env.test?
  Check::OpenTelemetryConfig.new(
    CheckConfig.get('otel_exporter_otlp_endpoint'),
    CheckConfig.get('otel_exporter_otlp_headers'),
    disable_exporting: ENV['CHECK_SKIP_HONEYCOMB'],
    disable_sampling: ENV['CHECK_SKIP_HONEYCOMB_SAMPLING']
  ).configure!(
    CheckConfig.get('otel_resource_attributes'),
    sampling_config: {
      sampler: CheckConfig.get('otel_traces_sampler'),
      rate: CheckConfig.get('otel_custom_sampling_rate')
    }
  )
else
  Check::OpenTelemetryTestConfig.configure!
end

# For creating manual instrumentation spans
CheckTracer = Check::OpenTelemetryConfig.tracer
