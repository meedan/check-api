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

  def checklist_format
    checklist = self.get_checklist
    unless checklist.blank?
      if !checklist.is_a?(Array)
        errors.add(:base, I18n.t(:invalid_format_for_checklist))
      else
        checklist.each do |task|
          if !task.is_a?(Hash) || (task.keys.map(&:to_sym) & [:description, :label, :type]).sort != [:description, :label, :type]
            errors.add(:base, I18n.t(:invalid_format_for_checklist))
          end
        end
      end
    end
  end

  def languages_format
    languages = self.get_languages
    unless languages.blank?
      if !languages.is_a?(Array)
        errors.add(:base, I18n.t(:invalid_format_for_languages))
      else
        languages.each do |language|
          if !language.is_a?(Hash) || language.keys.map(&:to_sym).sort != [:id, :title]
            errors.add(:base, I18n.t(:invalid_format_for_languages))
          end
        end
      end
    end
  end

  def parent_is_not_archived(parent, message)
    errors.add(:base, message) if parent && parent.archived
  end

  RESERVED_TEAM_SLUGS = ['check']

  def slug_is_not_reserved
    errors.add(:slug, I18n.t(:slug_is_reserved)) if RESERVED_TEAM_SLUGS.include?(self.slug)
  end

  def custom_media_statuses_format
    self.custom_statuses_format(:media)
  end

  def custom_source_statuses_format
    self.custom_statuses_format(:source)
  end

  def custom_statuses_format(type)
    statuses = self.send("get_#{type}_verification_statuses")
    if !statuses.is_a?(Hash) || statuses[:label].blank? || !statuses[:statuses].is_a?(Array) || statuses[:statuses].size === 0
      errors.add(:base, I18n.t(:invalid_format_for_custom_verification_status))
    else
      validate_statuses(statuses)
    end
  end

  def validate_statuses(statuses)
    statuses[:statuses].each do |status|
      errors.add(:base, I18n.t(:invalid_statuses_format_for_custom_verification_status)) if status.keys.map(&:to_sym).sort != [:completed, :description, :id, :label, :style]
      errors.add(:base, I18n.t(:invalid_id_or_label_for_custom_verification_status)) if status[:id].blank? || status[:label].blank?
    end
    [:default, :active].each do |status|
      errors.add(:base, I18n.t(":invalid_#{status}_status_for_custom_verification_status")) if !statuses[status].blank? && !statuses[:statuses].map { |s| s[:id] }.include?(statuses[status])
    end
  end
end
