class TiplineSearchResult
  attr_accessor :id, :team, :title, :body, :image_url, :language, :url, :type, :format

  def initialize(id:, team:, title:, body:, image_url:, language:, url:, type:, format:)
    self.id = id
    self.team = team
    self.title = title
    self.body = body
    self.image_url = image_url
    self.language = language
    self.url = url
    self.type = type # :explainer or :fact_check
    self.format = format # :text or :image
  end

  def should_send_in_language?(language)
    return true if self.team.get_languages.to_a.size < 2
    tbi = TeamBotInstallation.where(team_id: self.team.id, user: BotUser.alegre_user).last
    should_send_report_in_different_language = !tbi&.alegre_settings&.dig('single_language_fact_checks_enabled')
    self.language == language || should_send_report_in_different_language
  end

  def team_report_setting_value(key, language)
    self.team.get_report.to_h.with_indifferent_access.dig(language, key)
  end

  def footer(language)
    footer = []
    prefixes = {
      whatsapp: 'WhatsApp: ',
      facebook: 'FB Messenger: m.me/',
      twitter: 'Twitter: twitter.com/',
      telegram: 'Telegram: t.me/',
      viber: 'Viber: ',
      line: 'LINE: ',
      instagram: 'Instagram: instagram.com/'
    }
    [:signature, :whatsapp, :facebook, :twitter, :telegram, :viber, :line, :instagram].each do |field|
      value = self.team_report_setting_value(field.to_s, language)
      footer << "#{prefixes[field]}#{value}" unless value.blank?
    end
    footer.join("\n")
  end

  def text(language = nil, hide_body = false)
    text = []
    text << "*#{self.title.strip}*" unless self.title.blank?
    text << self.body.to_s unless hide_body
    text << self.url unless self.url.blank?
    text = text.collect do |part|
      self.team.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(part, self.team.get_outgoing_urls_utm_code) : part
    end
    unless language.nil?
      footer = self.footer(language)
      text << footer if !footer.blank? && self.team_report_setting_value('use_signature', language)
    end
    text.join("\n\n")
  end
end
