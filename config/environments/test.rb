require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  # config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Rails deprecation warnings are noisy, so we silence them in test mode
  # for now so that we don't muck up CI. We will need to come up with a
  # different approach in future, since this is one of the more useful places
  # we currently see them.
  #
  # The usual default is :stderr
  config.active_support.deprecation = :silence # :stderr

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # https://guides.rubyonrails.org/caching_with_rails.html#cache-stores
  config.cache_store = :file_store, "#{Rails.root}/tmp/cache#{ENV['TEST_ENV_NUMBER']}"

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # http://guides.rubyonrails.org/configuring.html#configuring-middleware
  config.allow_concurrency = true

  # Disable PaperTrail by default on tests
  # https://github.com/paper-trail-gem/paper_trail#7-testing
  config.after_initialize do
    PaperTrail.enabled = ENV['PAPERTRAIL_ENABLED'] || false
  end
end
