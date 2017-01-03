class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media
  belongs_to :user

  after_create :set_initial_media_status, :add_elasticsearch_data

  notifies_slack on: :create,
                 if: proc { |pm| m = pm.media; User.current.present? && m.current_team.present? && m.current_team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |pm| pm.slack_notification_message },
                 channel: proc { |pm| m = pm.media; m.project.setting(:slack_channel) || m.current_team.setting(:slack_channel) },
                 webhook: proc { |pm| m = pm.media; m.current_team.setting(:slack_webhook) }

  notifies_pusher on: :create,
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project] },
                  data: proc { |pm| pm.media.to_json }

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def media_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def set_initial_media_status
    st = Status.new
    st.annotated = self.media
    st.context = self.project
    st.annotator = self.user
    st.status = Status.default_id(self.media, self.project)
    st.created_at = self.created_at
    st.save!
  end

  def slack_notification_message
    m = self.media
    data = m.data(self.project)
    type, text = m.quote.blank? ?
      [ 'link', data['title'] ] :
      [ 'claim', m.quote ]
    "*#{m.user.name}* added a new #{type}: <#{m.origin}/project/#{m.project_id}/media/#{m.id}|*#{text}*>"
  end

  def add_elasticsearch_data
    p = self.project
    m = self.media
    ms = MediaSearch.new
    ms.id = self.id
    ms.team_id = p.team.id
    ms.project_id = p.id
    ms.set_es_annotated(self)
    ms.status = m.last_status(self.project)
    data = m.data(self.project)
    unless data.nil?
      ms.title = data['title']
      ms.description = data['description']
      ms.quote = m.quote
    end
    ms.save!
    #ElasticSearchWorker.perform_in(1.second, YAML::dump(ms), YAML::dump({}), 'add_parent')
  end

end
