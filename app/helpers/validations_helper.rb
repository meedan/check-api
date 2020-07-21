module ValidationsHelper
  def slack_channel_format
    channel = self.get_slack_channel
    if !channel.blank? && /\A[#@]/.match(channel).nil?
      self.errors.add(:base, I18n.t(:slack_channel_format_wrong))
    end
  end

  def slack_webhook_format
    webhook = self.get_slack_webhook
    if !webhook.blank? && /\Ahttps?:\/\/hooks\.slack\.com\/services\/[^\s]+\z/.match(webhook).nil?
      errors.add(:base, I18n.t(:slack_webhook_format_wrong))
    end
  end

  def parent_is_not_archived(parent, message)
    errors.add(:base, message) if parent && parent.archived
  end

  RESERVED_TEAM_SLUGS = ['check']

  def slug_is_not_reserved
    errors.add(:slug, I18n.t(:slug_is_reserved)) if RESERVED_TEAM_SLUGS.include?(self.slug)
  end

  def language_format
    language = self.get_language
    unless language.blank?
      errors.add(:base, I18n.t(:language_format_invalid)) unless language =~ /^[a-z]{2}(_[A-Z]{2})?$/
    end
  end

  def languages_format
    languages = self.get_languages
    unless languages.blank?
      errors.add(:base, I18n.t(:languages_format_invalid)) if !languages.is_a?(Array) || !languages.reject{ |l| l =~ /^[a-z]{2}(_[A-Z]{2})?$/ }.empty?
    end
  end
end
