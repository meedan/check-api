# Check API

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

## Observability

We use Honeycomb for monitoring information about our application. It is currently configured to report to suppress Honeycomb
reporting when the open telemetry required config is unset, which we would expect in development and test environments; however it is
possible to report data from your local environment to either console or remotely to Honeycomb for troubleshooting purposes.

If you would like to see data reported from your local machine, do the following:

**Local console**
1. Make sure that the `otel` prefixed values are set in `config.yml` following `config.yml.example`. The values provided in `config.yml.example` can be used since we don't need a real API key.
1. In `initializers/open_telemetry.rb`, uncomment the line setting exporter to 'console'. Warning: this is noisy!
1. Restart the server
1. View output in local server logs

**On Honeycomb**
1. Make sure that the `otel` prefixed values are set in `config.yml` following `config.yml.example`
1. In the config key `otel_exporter_otlp_headers`, set `x-honeycomb-team` to a Honeycomb API key for the Development environment (a sandbox where we put anything). This can be found in the [Honeycomb web interface](https://ui.honeycomb.io/meedan/environments/dev/api_keys). To track your own reported info, be sure to set the `otel_resource_attributes.developer.name` key in `config.yml` to your own name or unique identifier (e.g. `christa`). You will need this to filter information on Honeycomb.
1. Restart the server
1. See reported information in Development environment on Honeycomb

### Configuring sampling

To enable sampling for Honeycomb, set the following configuration (either in `config.yml` locally, or via environment for deployments):

* `otel_traces_sampler` to a supported sampler. See the Open Telemetry documentaiton for supported values.
* `otel_custom_sampling_rate` to an integer value. This will be used to calculate and set OTEL_TRACES_SAMPLER_ARG (1 / `<sample_rate>`) and to append sampler-related value to `OTEL_RESOURCE_ATTRIBUTES` (as `SampleRate=<sample_rate>`).

**Note**: If sampling behavior is changed in Check API, we will also need to update the behavior to match in any other application reporting to Honeycomb. More [here](https://docs.honeycomb.io/getting-data-in/opentelemetry/ruby/#sampling)

### Environment overrides

Often for rake tasks or background jobs, we will either want none of the data (skip reporting) or all of the data (skip sampling). For these cases we can set specific environment variables:

* To skip reporting to Honeycomb, set `CHECK_SKIP_HONEYCOMB` to `true`
* To skip sampling data we want to report to Honeycomb, set `CHECK_SKIP_HONEYCOMB_SAMPLING` to `true`
