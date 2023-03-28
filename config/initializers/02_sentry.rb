Sentry.init do |config|
  config.dsn = CheckConfig.get('sentry_dsn')
  config.environment = CheckConfig.get('sentry_environment')

  # Turns off trace reporting entirely by default, since we are currently using Honeycomb.
  # Can be modified via config, with a sentry_traces_sample_rate of 0 < x < 1
  config.traces_sample_rate = (CheckConfig.get('sentry_traces_sample_rate') || 0).to_f

  # Any exceptions we want to prevent sending to Sentry
  # config.excluded_exceptions += ['Check::Exception::RetryLater']

  # Ignore exceptions raised in Sidekiq jobs unless they pass their retry limit
  # Ideally in future, we would not set this and instead would manually raise retryable
  # exceptions and ignore them until last retry, and let all other raised exceptions
  # be reported as they happen.
  config.sidekiq.report_after_job_retries = true
end
