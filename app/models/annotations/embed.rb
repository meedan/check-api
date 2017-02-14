class Embed < ActiveRecord::Base
  include SingletonAnnotationBase

  attr_accessible

  field :title
  field :description
  field :embed
  field :username
  field :published_at, Integer

  notifies_slack on: :save,
                 if: proc { |em| em.should_notify? and em.check_title_update },
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
    data = self.annotated.embed
    changeset = self.versions.last.changeset["data"]
    "*#{User.current.name}* changed the title from *#{changeset[0]['title']}* to <#{CONFIG['checkdesk_client']}/#{self.annotated.project.team.slug}/project/#{self.annotated.project_id}/media/#{self.annotated_id}|#{data['title']}>"
  end

  def check_title_update
    notify = true
    if self.annotated.media.type == 'Claim'
      notify = false if self.versions.size == 1
    end
    notify
  end

  def update_elasticsearch_embed
    self.update_media_search(%w(title description)) if self.annotated_type == 'ProjectMedia'
  end

end
