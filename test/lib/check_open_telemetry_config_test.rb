require_relative '../test_helper'
require_relative '../../lib/check_open_telemetry_config'

class OpenTelemetryConfigTest < ActiveSupport::TestCase
  test "configures open telemetry to report remotely when exporting enabled" do
    env_var_original_state = {}
    Check::OpenTelemetryConfig::ENV_CONFIG.map do|env_var|
      return unless ENV[env_var]
      env_var_original_state[env_var] = ENV.delete(env_var)
    end

    Check::OpenTelemetryConfig.new('https://fake.com','foo=bar').configure!({'developer.name' => 'piglet'})

    assert_equal 'otlp', ENV['OTEL_TRACES_EXPORTER']
    assert_equal 'https://fake.com', ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
    assert_equal 'foo=bar', ENV['OTEL_EXPORTER_OTLP_HEADERS']
    assert_equal 'developer.name=piglet', ENV['OTEL_RESOURCE_ATTRIBUTES']
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  test "configures open telemetry to have nil exporter when exporting disabled, and leaves other exporter settings blank" do
    env_var_original_state = {}
    Check::OpenTelemetryConfig::ENV_CONFIG.map do|env_var|
      return unless ENV[env_var]
      env_var_original_state[env_var] = ENV.delete(env_var)
    end

    Check::OpenTelemetryConfig.new('','').configure!({'developer.name' => 'piglet'})

    assert ENV['OTEL_TRACES_EXPORTER'].nil?
    assert_empty ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
    assert_empty ENV['OTEL_EXPORTER_OTLP_HEADERS']
    assert_equal 'developer.name=piglet', ENV['OTEL_RESOURCE_ATTRIBUTES']
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  # exporting_disabled?
  test "should disable exporting if any required config missing" do
    assert Check::OpenTelemetryConfig.new(nil, nil).send(:exporting_disabled?)
    assert Check::OpenTelemetryConfig.new('https://fake.com', '').send(:exporting_disabled?)

    assert !Check::OpenTelemetryConfig.new('https://fake.com', 'foo=bar').send(:exporting_disabled?)
  end

  test "should disable exporting if override set" do
    assert Check::OpenTelemetryConfig.new('https://fake.com', 'foo=bar', 'true').send(:exporting_disabled?)
  end

  # format_attributes
  test "should format attributes from hash to string, if present" do
    assert !Check::OpenTelemetryConfig.new(nil,nil).send(:format_attributes, nil)

    attr_string = Check::OpenTelemetryConfig.new(nil,nil).send(:format_attributes, {'developer.name' => 'piglet', 'favorite.food' => 'ham'})
    assert_equal "developer.name=piglet,favorite.food=ham", attr_string
  end
end
