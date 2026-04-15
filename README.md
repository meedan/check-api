# Check API

[![Build and Run Tests](https://github.com/meedan/check-api/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/meedan/check-api/actions/workflows/ci-tests.yml)

Part of the [Check platform](https://meedan.com/check). Refer to the [main repository](https://github.com/meedan/check) for instructions.

## Development

## Error reporting

We use Sentry for tracking exceptions in our application.

By default we unset `sentry_dsn` in the `config.yml`, which prevents
information from being reported to Sentry. If you would like to see data reported from your local machine, set `sentry_dsn` to the value provided for Pender in the Sentry app.

Additional configuration:

**In config.yml**
  * `sentry_dsn` - the secret that allows us to send information to Sentry, available in the Sentry web app. Scoped to a service (e.g. Check API)
  * `sentry_environment` - the environment reported to Sentry (e.g. dev, QA, live)
  * `sentry_traces_sample_rate` - not currently used, since we don't use Sentry for tracing. Set to 0 in config as result.

**In `02_sentry.rb`**
  * `config.excluded_exceptions` - a list of exception classes that we don't want to send to Sentry
