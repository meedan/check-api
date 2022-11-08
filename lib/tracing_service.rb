# A convenience wrapper class for Open Telemetry
class TracingService
  class << self
    def add_attribute_to_current_span(attribute_name, value)
      current_span = OpenTelemetry::Trace.current_span
      current_span.set_attribute(attribute_name, value.to_s)
    end
  end
end
