require 'test_helper'
require 'minitest/autorun'

class TracingServiceTest < ActiveSupport::TestCase
  test "#add_attribute_to_current_span should set attributes via open telemetry" do
    fake_span = mock('span')
    fake_span.expects(:set_attribute).with('foo', 'bar')
    OpenTelemetry::Trace.expects(:current_span).returns(fake_span)

    TracingService.add_attribute_to_current_span('foo', :bar)
  end
end
