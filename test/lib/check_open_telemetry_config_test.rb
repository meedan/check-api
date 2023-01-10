require_relative '../test_helper'
require_relative '../../lib/check_open_telemetry_config'

# Testing the real config
class OpenTelemetryConfigTest < ActiveSupport::TestCase
  ENV_CONFIG_TO_RESET = %w(
    OTEL_TRACES_EXPORTER
    OTEL_EXPORTER_OTLP_ENDPOINT
    OTEL_EXPORTER_OTLP_HEADERS
    OTEL_RESOURCE_ATTRIBUTES
    OTEL_TRACES_SAMPLER
    OTEL_TRACES_SAMPLER_ARG
  )

  def cache_and_clear_env
    {}.tap do |original_state|
      ENV_CONFIG_TO_RESET.each do|env_var|
        next unless ENV[env_var]
        original_state[env_var] = ENV.delete(env_var)
      end
    end
  end

  test "configures open telemetry to report remotely when exporting enabled" do
    env_var_original_state = cache_and_clear_env

    Check::OpenTelemetryConfig.new('https://fake.com','foo=bar').configure!({'developer.name' => 'piglet'})

    assert_equal 'otlp', ENV['OTEL_TRACES_EXPORTER']
    assert_equal 'https://fake.com', ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
    assert_equal 'foo=bar', ENV['OTEL_EXPORTER_OTLP_HEADERS']
    assert_equal 'developer.name=piglet', ENV['OTEL_RESOURCE_ATTRIBUTES']
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  test "configures open telemetry to have nil exporter when exporting disabled, and leaves other exporter settings blank" do
    env_var_original_state = cache_and_clear_env

    Check::OpenTelemetryConfig.new('','').configure!({'developer.name' => 'piglet'})

    assert_equal 'none', ENV['OTEL_TRACES_EXPORTER']
    assert_nil ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
    assert_nil ENV['OTEL_EXPORTER_OTLP_HEADERS']
    assert_equal 'developer.name=piglet', ENV['OTEL_RESOURCE_ATTRIBUTES']
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  test "sets provided sampling config in the environment" do
    env_var_original_state = cache_and_clear_env

    Check::OpenTelemetryConfig.new('https://fake.com','foo=bar').configure!(
      {'developer.name' => 'piglet' },
      sampling_config: { sampler: 'traceidratio', rate: '2' }
    )

    assert_equal 'traceidratio', ENV['OTEL_TRACES_SAMPLER']
    assert_equal '0.5', ENV['OTEL_TRACES_SAMPLER_ARG']
    assert_equal 'developer.name=piglet,SampleRate=2', ENV['OTEL_RESOURCE_ATTRIBUTES']
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  test "does not set the sampler arguments when sampling config cannot be set properly" do
    env_var_original_state = cache_and_clear_env

    Check::OpenTelemetryConfig.new('https://fake.com','foo=bar').configure!(
      {'developer.name' => 'piglet' },
      sampling_config: { sampler: 'traceidratio', rate: 'asdf' }
    )

    assert_nil ENV['OTEL_TRACES_SAMPLER_ARG']
    assert_equal 'developer.name=piglet', ENV['OTEL_RESOURCE_ATTRIBUTES']

    # Keeps sampler, since it could be something like alwayson or alwaysoff, which does
    # not require a sample rate
    assert_equal 'traceidratio', ENV['OTEL_TRACES_SAMPLER']
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  test "gracefully handles unset attributes" do
    env_var_original_state = cache_and_clear_env

    Check::OpenTelemetryConfig.new('https://fake.com','foo=bar').configure!(nil)
    assert ENV['OTEL_RESOURCE_ATTRIBUTES'].blank?
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  # .tracer
  test "returns a configured tracer" do
    env_var_original_state = cache_and_clear_env

    tracer = Check::OpenTelemetryConfig.tracer

    assert tracer.is_a?(OpenTelemetry::Trace::Tracer)
  ensure
    env_var_original_state.each{|env_var, original_state| ENV[env_var] = original_state}
  end

  # .exporting_disabled?
  test "should disable exporting if any required config missing" do
    assert Check::OpenTelemetryConfig.new(nil, nil).send(:exporting_disabled?)
    assert Check::OpenTelemetryConfig.new('https://fake.com', '').send(:exporting_disabled?)

    assert !Check::OpenTelemetryConfig.new('https://fake.com', 'foo=bar').send(:exporting_disabled?)
  end

  test "should disable exporting if override set" do
    assert Check::OpenTelemetryConfig.new('https://fake.com', 'foo=bar', 'true').send(:exporting_disabled?)
  end

  # .format_attributes
  test "should format attributes from hash to string, if present" do
    assert !Check::OpenTelemetryConfig.new(nil,nil).send(:format_attributes, nil)

    attr_string = Check::OpenTelemetryConfig.new(nil,nil).send(:format_attributes, {'developer.name' => 'piglet', 'favorite.food' => 'ham'})
    assert_equal "developer.name=piglet,favorite.food=ham", attr_string
  end
end
