# Check API

[![Test Coverage](https://api.codeclimate.com/v1/badges/583c7f562a78e7039e13/test_coverage)](https://codeclimate.com/github/meedan/check-api/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/583c7f562a78e7039e13/maintainability)](https://codeclimate.com/github/meedan/check-api/maintainability)
[![Travis](https://travis-ci.org/meedan/check-api.svg?branch=develop)](https://travis-ci.org/meedan/check-api/)

Part of the [Check platform](https://meedan.com/check). Refer to the [main repository](https://github.com/meedan/check) for instructions.

## Development

### Observability

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

#### Configuring sampling

To enable sampling for Honeycomb, set the following configuration (either in `config.yml` locally, or via environment for deployments):

* `otel_traces_sampler` to a supported sampler. See the Open Telemetry documentaiton for supported values.
* `otel_custom_sampling_rate` to an integer value. This will be used to calculate and set OTEL_TRACES_SAMPLER_ARG (1 / `<sample_rate>`) and to append sampler-related value to `OTEL_RESOURCE_ATTRIBUTES` (as `SampleRate=<sample_rate>`).

**Note**: If sampling behavior is changed in Check API, we will also need to update the behavior to match in any other application reporting to Honeycomb. More [here](https://docs.honeycomb.io/getting-data-in/opentelemetry/ruby/#sampling)

#### Environment overrides

Often for rake tasks or background jobs, we will either want none of the data (skip reporting) or all of the data (skip sampling). For these cases we can set specific environment variables:

* To skip reporting to Honeycomb, set `CHECK_SKIP_HONEYCOMB` to `true`
* To skip sampling data we want to report to Honeycomb, set `CHECK_SKIP_HONEYCOMB_SAMPLING` to `true`

## Testing

Running tests with argument `-n` (used for running an individual test via `ruby`) or environment variable `MINIMAL_TEST_RUN` set to true (i.e. `MINIMAL_TEST_RUN=true bin/rails test test/models/tipline_message_test.rb`) will force tests not to retry and skip generating a coverage report. This is intended to speed up individual runs of tests locally.
