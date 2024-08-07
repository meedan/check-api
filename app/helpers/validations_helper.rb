module ValidationsHelper
  def slack_webhook_format
    webhook = self.get_slack_webhook
    if !webhook.blank? && /https?:\/\/hooks\.slack\.com/.match(webhook).nil?
      errors.add(:base, I18n.t(:slack_webhook_format_wrong))
    end
  end

  def parent_is_not_archived(parent, message)
    errors.add(:base, message) if parent && parent.archived > CheckArchivedFlags::FlagCodes::NONE
  end

  RESERVED_TEAM_SLUGS = ['check']

  def slug_is_not_reserved
    errors.add(:slug, I18n.t(:slug_is_reserved)) if RESERVED_TEAM_SLUGS.include?(self.slug)
  end

  def language_format
    language = self.get_language
    unless language.blank?
      errors.add(:base, I18n.t(:language_format_invalid)) unless language =~ CheckCldr::LANGUAGE_FORMAT_REGEXP
    end
  end

  def languages_format
    languages = self.get_languages
    unless languages.blank?
      errors.add(:base, I18n.t(:languages_format_invalid)) if !languages.is_a?(Array) || !languages.reject{ |l| l =~ CheckCldr::LANGUAGE_FORMAT_REGEXP }.empty?
    end
  end

  def fieldsets_format
    schema = {
      type: 'array',
      title: 'Fieldsets',
      items: {
        type: 'object',
        title: 'Fieldset',
        required: ['identifier', 'singular', 'plural'],
        properties: {
          identifier: { type: 'string', title: 'Identifier', pattern: '^[0-9a-z_]+$' },
          singular: { type: 'string', title: 'Singular' },
          plural: { type: 'string', title: 'Plural' }
        }
      }
    }
    fieldsets = self.get_fieldsets
    errors.add(:settings, JSON::Validator.fully_validate(schema, fieldsets)) if !JSON::Validator.validate(schema, fieldsets)
  end

end
