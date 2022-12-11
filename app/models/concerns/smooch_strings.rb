
require 'active_support/concern'

TIPLINE_STRINGS = YAML.load(File.read(File.join(Rails.root, 'config', 'tipline_strings.yml'))).with_indifferent_access

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      strings = TIPLINE_STRINGS[language] || TIPLINE_STRINGS[language.gsub(/[-_].*$/, '')] || TIPLINE_STRINGS['en']
      strings[key] || key
    end
  end
end
