module ValidationsHelper

  def slack_channel_format
    channel = self.get_slack_channel
    if !channel.blank? && /\A#/.match(channel).nil?
      self.errors.add(:base, I18n.t(:slack_channel_format_wrong, default: 'Slack channel is invalid, it should have the format #general'))
    end
  end

  def slack_webhook_format
    webhook = self.get_slack_webhook
    if !webhook.blank? && /\Ahttps?:\/\/hooks\.slack\.com\/services\/[^\s]+\z/.match(webhook).nil?
      errors.add(:base, I18n.t(:slack_webhook_format_wrong, default: 'Slack webhook is invalid, it should have the format `https://hooks.slack.com/services/XXXXX/XXXXXXXXXX`'))
    end
  end

  def checklist_format
    checklist = self.get_checklist
    unless checklist.blank?
      error_message = "Checklist is invalid, it should have the format [ { 'label': 'XXXX', 'type': 'free_text','description': 'YYYY', 'projects': [], 'jsonoptions': '[{ \'label\': \'YYYY\' }]' } ]"
      if !checklist.is_a?(Array)
        errors.add(:base, I18n.t(:invalid_format_for_checklist, default: error_message))
      else
        checklist.each do |task|
          if !task.is_a?(Hash) || (task.keys.map(&:to_sym) & [:description, :label, :type]).sort != [:description, :label, :type]
            errors.add(:base, I18n.t(:invalid_format_for_checklist, default: error_message))
          end
        end
      end
    end
  end

  def languages_format
    languages = self.get_languages
    unless languages.blank?
      error_message = "Languages is invalid, it should have the format [{'id': 'en','title': 'English'}]"
      if !languages.is_a?(Array)
        errors.add(:base, I18n.t(:invalid_format_for_languages, default: error_message))
      else
        languages.each do |language|
          if !language.is_a?(Hash) || language.keys.map(&:to_sym).sort != [:id, :title]
            errors.add(:base, I18n.t(:invalid_format_for_languages, default: error_message))
          end
        end
      end
    end
  end
end
