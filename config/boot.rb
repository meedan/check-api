ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Monkey-patch to allow YAML aliases with Bootsnap

require 'psych'

module Psych
  class << self
    alias_method :old_load, :load

    def load(yaml, permitted_classes: [Time, Symbol], aliases: true, **kwargs)
      old_load(yaml, permitted_classes: permitted_classes, aliases: aliases, **kwargs)
    end

    alias_method :old_safe_load, :safe_load

      def safe_load(yaml, permitted_classes: [Time, Symbol], aliases: true, **kwargs)
      old_safe_load(yaml, permitted_classes: permitted_classes, aliases: aliases, **kwargs)
    end
  end
end
