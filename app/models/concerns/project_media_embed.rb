require 'active_support/concern'

module ProjectMediaEmbed
  extend ActiveSupport::Concern

  def oembed_url
    self.project.team.private ? '' : CONFIG['checkdesk_base_url'] + '/api/project_medias/' + self.id.to_s + '/oembed'
  end

  def author_name
    self.user.nil? ? '' : self.user.name
  end

  def author_url
    (self.user && self.user.accounts.first) ? self.user.accounts.first.url : ''
  end

  def author_picture
    self.user.nil? ? '' : self.user.profile_image
  end

  def author_username
    self.user.nil? ? '' : self.user.login
  end

  def author_role
    role = self.user.nil? ? '' : self.user.role(self.project.team).to_s
    role.blank? ? 'none' : role
  end

  def source_url
    self.media.is_a?(Link) ? self.media.url : self.full_url
  end
  
  def completed_tasks
    self.annotations.where(annotation_type: 'task').map(&:load).select{ |t| t.status == 'Resolved' }
  end

  def completed_tasks_count
    self.completed_tasks.count
  end

  def comments
    self.annotations.where(annotation_type: 'comment').map(&:load)
  end

  def comments_count
    self.comments.count
  end

  def provider
    self.media.is_a?(Link) ? self.media.provider : CONFIG['app_name']
  end

  def published_at
    self.embed['published_at'].blank? ? self.created_at : DateTime.parse(self.embed['published_at'])
  end

  def source_author
    data = {}
    if self.media.is_a?(Link)
      data[:author_picture] = self.embed['author_picture']
      data[:author_url] = self.embed['author_url']
      data[:author_name] = self.embed['author_name']
      data[:author_username] = self.embed['username']
    else
      data[:author_picture] = self.author_picture
      data[:author_url] = self.author_url
      data[:author_name] = self.author_name
      data[:author_username] = self.author_username
    end
    data
  end

  def metadata
    {
      title: self.title.to_s,
      description: self.text.to_s,
      picture: self.media.picture.to_s,
      permalink: self.full_url.to_s,
      oembed_url: CONFIG['checkdesk_base_url'] + '/api/project_medias/' + self.id.to_s + '/oembed',
      embed_url: CONFIG['pender_host'] + '/api/medias.html?url=' + self.full_url.to_s
    }.to_json
  end

  def as_oembed(options = {})
    {
      type: 'rich',
      version: '1.0',
      title: self.title.to_s,
      author_name: self.author_name,
      author_url: self.author_url,
      provider_name: CONFIG['app_name'] || '',
      provider_url: CONFIG['app_url'] || '',
      thumbnail_url: self.media.picture.to_s,
      html: self.html(options),
      width: options[:maxwidth] || 800,
      height: options[:maxheight] || 800
    }.with_indifferent_access
  end

  def html(options = {})
    av = ActionView::Base.new(Rails.root.join('app', 'views'))
    av.assign({ project_media: self, source_author: self.source_author }.merge(options))
    av.render(template: 'project_medias/oembed.html.erb', layout: nil)
  end
end
