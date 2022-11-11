# A convenience wrapper class for Open Telemetry
class TracingService
  class << self
    def add_attributes_to_current_span(attributes)
      current_span = OpenTelemetry::Trace.current_span
      current_span.add_attributes(format_attributes(attributes))
    end

    private

    def format_attributes(attributes)
      attributes.compact
    end
  end
end
