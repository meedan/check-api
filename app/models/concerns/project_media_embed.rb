require 'active_support/concern'

module ProjectMediaEmbed
  extend ActiveSupport::Concern

  def oembed_url(format = '')
    format = ".#{format}" unless format.blank?
    url = CheckConfig.get('checkdesk_base_url') + '/api/project_medias/' + self.id.to_s + '/oembed' + format
    request = RequestStore[:request]
    url += '?' + request.query_string if request.present? && !request.query_string.blank?
    url
  end

  def embed_url(shorten = true)
    url = CheckConfig.get('pender_url') + '/api/medias.html?url=' + self.full_url.to_s
    return url unless shorten && CheckConfig.get('short_url_host')
    key = Shortener::ShortenedUrl.generate!(url).unique_key
    CheckConfig.get('short_url_host') + '/' + key
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
    role = self.user.nil? ? '' : self.user.role(self.team).to_s
    role.blank? ? 'none' : role
  end

  def source_url
    self.media.is_a?(Link) ? self.media.url : self.full_url
  end

  def provider
    self.media.is_a?(Link) ? self.media.provider : CheckConfig.get('app_name')
  end

  def published_at
    p = self.media&.metadata&.dig('published_at')
    p.blank? ? nil : (p.is_a?(Numeric) ? Time.at(p).utc : DateTime.parse(p).utc)
  end

  def source_author
    data = {}
    if self.media.is_a?(Link)
      data[:author_picture] = self.media.metadata['author_picture']
      data[:author_url] = self.media.metadata['author_url']
      data[:author_name] = self.media.metadata['author_name']
      data[:author_username] = self.media.metadata['username']
    else
      data[:author_picture] = self.author_picture
      data[:author_url] = self.author_url
      data[:author_name] = self.author_name
      data[:author_username] = self.author_username
    end
    data
  end

  def all_tasks
    self.annotations.where(annotation_type: 'task').map(&:load).reject{ |t| t.nil? }
  end

  def completed_tasks_count
    self.completed_tasks.count
  end

  def open_tasks
    self.all_tasks.select{ |t| t.responses.count == 0 }
  end

  def completed_tasks
    self.all_tasks.select{ |t| t.responses.count > 0 }
  end

  def oembed_metadata
    {
      title: self.title.to_s,
      description: self.description.to_s,
      picture: self.media.picture.to_s,
      permalink: self.full_url.to_s,
      oembed_url: self.oembed_url,
      embed_url: self.embed_url
    }.to_json
  end

  def mark_as_embedded
    if self.get_annotations('embed_code').empty?
      user_current = User.current
      User.current = User.new
      a = Dynamic.new
      a.skip_check_ability = true
      a.annotated = self
      a.annotation_type = 'embed_code'
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.set_fields = { embed_code_copied: true }.to_json
      a.save!
      User.current = user_current
    end
  end

  def as_oembed(options = {})
    self.mark_as_embedded

    {
      type: 'rich',
      version: '1.0',
      title: self.title.to_s,
      author_name: self.author_name,
      author_url: self.author_url,
      provider_name: CheckConfig.get('app_name', ''),
      provider_url: CheckConfig.get('app_url', ''),
      thumbnail_url: self.media.picture.to_s,
      html: self.oembed_html(options),
      width: options[:maxwidth] || 800,
      height: options[:maxheight] || 800
    }.with_indifferent_access
  end

  def oembed_html(options)
    w = options[:maxwidth] || 800
    h = options[:maxheight] || 800
    options[:from_pender] ? self.html(options) : "<iframe src=\"#{self.oembed_url('html')}\" width=\"#{w}\" height=\"#{h}\" />"
  end

  def html(options = {})
    options = options.permit(options.keys) if options.respond_to?(:permit)

    ApplicationController.render(
      assigns: { project_media: self, source_author: self.source_author }.merge(options),
      template: 'project_medias/oembed.html.erb',
      layout: nil
    )
  end

  def last_status_color
    self.status_color(self.last_status)
  end

  def status_color(status_id)
    statuses = Workflow::Workflow.options(self, self.default_project_media_status_type)
    statuses = statuses.with_indifferent_access['statuses']
    color = nil
    statuses.each do |status|
      color = (status['style']['backgroundColor'] || status['style']['color']) if status['id'] == status_id
    end
    color
  end

  def clear_caches
    return if self.skip_clear_cache || RequestStore.store[:skip_clear_cache]
    ProjectMedia.delay_for(1.second, retry: 0).clear_caches(self.id)
  end

  module ClassMethods
    def clear_caches(pmid)
      pm = ProjectMedia.where(id: pmid).last
      return if pm.nil?

      url = pm.full_url.to_s
      PenderClient::Request.get_medias(CheckConfig.get('pender_url_private'), { url: url, refresh: '1' }, CheckConfig.get('pender_key'))
      CcDeville.clear_cache_for_url(url)

      # Clear Pender cache, both URL-encoded and unencoded because each can end up being used.
      CcDeville.clear_cache_for_url(CheckConfig.get('pender_url') + '/api/medias.html?url=' + url)
      CcDeville.clear_cache_for_url(CheckConfig.get('pender_url') + '/api/medias.html?url=' + ERB::Util.url_encode(url))
    end
  end
end
