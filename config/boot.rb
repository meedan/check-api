ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
# https://github.com/Shopify/bootsnap/issues/110
ENV['BOOTSNAP_CACHE_DIR'] = File.expand_path("../tmp/cache#{ENV['TEST_ENV_NUMBER']}", __dir__) if ENV['RAILS_ENV'] == 'test'

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
