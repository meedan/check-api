require 'active_support/concern'

TIPLINE_STRINGS = YAML.load(File.read(File.join(Rails.root, 'config', 'tipline_strings.yml'))).with_indifferent_access

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language, truncate_at = 1024)
      # Truncation happens because WhatsApp has limitations:
      # - Section title: 24 characters
      # - Menu item title: 24 characters
      # - Menu item description: 72 characters
      # - Button label: 20 characters
      # - Body: 1024 characters
      string = [TIPLINE_STRINGS.dig(language, key), TIPLINE_STRINGS.dig(language.gsub(/[-_].*$/, ''), key), TIPLINE_STRINGS.dig('en', key)].find{ |s| !s.blank? }
      string = key if string.blank?
      string.to_s.truncate(truncate_at)
    end
  end
end
