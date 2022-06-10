
require 'active_support/concern'

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      yaml = YAML.load(File.read(File.join(Rails.root, 'config', 'tipline_strings.yml')))
      language = language.gsub(/[-_].*$/, '')
      strings = yaml[language] || yaml['en']
      strings[key]
    end
  end
end
