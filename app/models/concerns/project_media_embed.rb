require 'active_support/concern'

module ProjectMediaEmbed
  extend ActiveSupport::Concern

  def oembed_url
    CONFIG['checkdesk_base_url'] + '/api/project_medias/' + self.id.to_s + '/oembed'
  end

  def as_oembed(options = {})
    {
      type: 'rich',
      version: '1.0',
      title: self.title.to_s,
      author_name: self.user.nil? ? '' : self.user.name,
      author_url: (self.user && self.user.accounts.first) ? self.user.accounts.first.url : '',
      provider_name: CONFIG['app_name'] || '',
      provider_url: CONFIG['app_url'] || '',
      thumbnail_url: self.media.picture.to_s,
      html: self.html,
      width: options[:maxwidth] || 800,
      height: options[:maxheight] || 800
    }.with_indifferent_access
  end

  def html
    ''
  end
end
