class Embed < ActiveRecord::Base
  include SingletonAnnotationBase

  field :title
  field :description
  field :embed
  field :username
  field :published_at, Integer
  field :refreshes_count, Integer

  after_commit :update_elasticsearch_embed, :send_slack_notification, on: [:create, :update]

  def content
    {
      title: self.title,
      description: self.description,
      username: self.username,
      published_at: self.published_at,
      embed: self.embed
    }.to_json
  end

  def slack_notification_message
    self.annotated.slack_notification_message(true) if self.annotated.respond_to?(:slack_notification_message)
  end

  def update_elasticsearch_embed
    unless self.annotated.nil?
      keys = %w(title description)
      if self.annotated_type == 'ProjectMedia'
        self.update_es_embed_pm_annotation(keys)
      elsif self.annotated_type == 'Media' && self.annotated.type == 'Link'
        self.annotated.project_medias.each do |pm|
          em = pm.get_annotations('embed').last
          self.update_elasticsearch_doc(keys, {}, pm) if em.nil?
        end
      end
    end
  end

  def update_es_embed_pm_annotation(keys)
    data = {}
    media_embed = self.annotated.media.embed
    overridden = self.annotated.overridden
    keys.each do |k|
      data[k] = [media_embed[k], self.send(k)] if overridden[k]
    end
    self.update_elasticsearch_doc(keys, data)
  end

  def embed_for_registration_account(data)
    unless data.nil?
      embed = {}
      embed['author_name'] = data.dig('info', 'name')
      embed['author_picture'] = data.dig('info', 'image')
      embed['author_url'] = data['url']
      embed['description'] = data.dig('info', 'description')
      embed['picture'] = data.dig('info', 'image')
      embed['provider'] = data['provider']
      embed['title'] = data.dig('info', 'name')
      embed['url'] = data['url']
      embed['username'] = data.dig('info', 'nickname') || data.dig('info', 'name')
      embed['parsed_at'] = Time.now
      embed['pender'] = false
      self.embed = embed.to_json
      self.save!
    end
  end

end
