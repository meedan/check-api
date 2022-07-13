require 'active_support/concern'

module SmoochLanguage
  extend ActiveSupport::Concern

  module ClassMethods
    def get_user_language(message, state = nil)
      uid = message['authorId']
      team = Team.find(self.config['team_id'])
      default_language = team.default_language
      supported_languages = self.get_supported_languages
      guessed_language = nil
      if state == 'waiting_for_message'
        Rails.cache.fetch("smooch:user_language:#{uid}") do
          guessed_language = self.get_language(message, default_language)
          guessed_language
        end
      end
      user_language = Rails.cache.read("smooch:user_language:#{uid}") || guessed_language || default_language
      supported_languages.include?(user_language) ? user_language : default_language
    end

    def reset_user_language(uid)
      Rails.cache.delete("smooch:user_language:#{uid}")
      Rails.cache.delete("smooch:user_language:#{self.config['team_id']}:#{uid}:confirmed")
    end

    def user_language_confirmed?(uid)
      !Rails.cache.read("smooch:user_language:#{self.config['team_id']}:#{uid}:confirmed").blank?
    end

    def get_supported_languages
      team = Team.find(self.config['team_id'])
      team_languages = team.get_languages || ['en']
      languages = []
      self.config['smooch_workflows'].each do |w|
        l = w['smooch_workflow_language']
        languages << l if team_languages.include?(l)
      end
      languages.sort
    end

    def should_ask_for_language_confirmation?(uid)
      self.is_v2? && self.get_supported_languages.size > 1 && !self.user_language_confirmed?(uid)
    end

    def get_language(message, fallback_language = 'en')
      text = message['text'].to_s
      lang = text.blank? ? nil : Bot::Alegre.get_language_from_alegre(text)
      lang = fallback_language if lang == 'und' || lang.blank? || !I18n.available_locales.include?(lang.to_sym)
      lang
    end
  end
end
