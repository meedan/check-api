require 'test_helper'
require 'minitest/autorun'

class TracingServiceTest < ActiveSupport::TestCase
  test "#add_attributes_to_current_span should set attributes via open telemetry" do
    fake_span = mock('span')
    fake_span.expects(:add_attributes).with({'foo' => 'bar'})
    OpenTelemetry::Trace.expects(:current_span).returns(fake_span)

    TracingService.add_attributes_to_current_span({'foo' => 'bar'})
  end

  test "#add_attributes_to_current_span discards empty values in hash" do
    fake_span = mock('span')
    fake_span.expects(:add_attributes).with({'bar' => 'baz'})
    OpenTelemetry::Trace.expects(:current_span).returns(fake_span)

    TracingService.add_attributes_to_current_span({'foo' => nil, 'bar' => 'baz'})
  end
end
