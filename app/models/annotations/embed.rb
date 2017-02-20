class Embed < ActiveRecord::Base
  include SingletonAnnotationBase

  field :title
  field :description
  field :embed
  field :username
  field :published_at, Integer

  notifies_slack on: :save,
                 if: proc { |em| em.should_notify? and em.title_is_overridden? },
                 message: proc { |em| em.slack_notification_message},
                 channel: proc { |em| em.annotated.project.setting(:slack_channel) || em.current_team.setting(:slack_channel) },
                 webhook: proc { |em| em.current_team.setting(:slack_webhook) }

  after_save :update_elasticsearch_embed

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
    data = self.overridden_data
    I18n.t(:slack_save_embed, default: "*%{user}* changed the title from *%{from}* to <%{to}>", user: User.current.name, from: data[0]['title'], to: "#{CONFIG['checkdesk_client']}/#{self.annotated.project.team.slug}/project/#{self.annotated.project_id}/media/#{self.annotated_id}|#{data[1]['title']}")
  end

  def title_is_overridden?
    overriden = false
    v = self.versions.last
    unless v.nil?
      data = v.changeset['data']
      # Get title from pender if Link has only one version
      if self.annotated.media.type == 'Link' and self.versions.size == 1
        pender = self.annotated.get_media_annotations('embed')
        data[0]['title'] = pender['data']['title'] unless pender.nil?
      end
      unless data[0].blank? and data[0]['title'].nil?
        overriden = true if data[0]['title'] != data[1]['title']
      end
    end
    self.overridden_data=data if overriden
    overriden
  end

  def overridden_data
    @overridden_data
  end

  def overridden_data=(data)
    @overridden_data = data
  end

  def update_elasticsearch_embed
    self.update_media_search(%w(title description)) if self.annotated_type == 'ProjectMedia'
  end
end
