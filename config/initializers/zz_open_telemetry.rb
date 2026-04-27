# For creating manual instrumentation spans
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'check-api'
end

CheckTracer = OpenTelemetry.tracer_provider.tracer('check-api')
