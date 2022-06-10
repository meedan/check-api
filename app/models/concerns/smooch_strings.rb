
require 'active_support/concern'

TIPLINE_STRINGS = YAML.load(File.read(File.join(Rails.root, 'config', 'tipline_strings.yml')))

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      language = language.gsub(/[-_].*$/, '')
      strings = TIPLINE_STRINGS[language] || TIPLINE_STRINGS['en']
      strings[key] || key
    end
  end
end
