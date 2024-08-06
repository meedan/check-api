module Check
  class OpenTelemetryTestConfig
    class << self
      def configure!
        # raise StandardError.new("[otel] Test config being used in non-test environment") unless Rails.env.test?

        # Supplement Open Telemetry config in initializer to capture spans in test
        # https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/.instrumentation_generator/templates/test/test_helper.rb

        # By default this discards spans. To enable recording for test purposes,
        # set the following in the test setup block:
        #     Check::OpenTelemetryTestConfig.current_exporter.recording = true
        @exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new(recording: false)
        OpenTelemetry::SDK.configure do |c|
          c.service_name = 'test-check-api'
          c.add_span_processor(OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(@exporter))

          # Keep Open Telemetry instrumentation in sync across environments,
          # so that we can catch any problems arising from instrumentation libraries
          # and configuration
          Check::OpenTelemetryConfig.configure_instrumentation!(c)
        end
        @exporter
      end

      def current_exporter
        @exporter || configure!
      end
    end
  end
end
