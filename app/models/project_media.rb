class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media

  notifies_slack on: :create,
                 if: proc { |pm| m = pm.media; m.current_user.present? && m.current_team.present? && m.current_team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |pm| m = pm.media; "<#{m.origin}/user/#{m.current_user.id}|*#{m.current_user.name}*> added an unverified link: <#{m.origin}/project/#{m.project_id}/media/#{m.id}|*#{m.data['title']}*>" },
                 channel: proc { |pm| m = pm.media; m.project.setting(:slack_channel) || m.current_team.setting(:slack_channel) },
                 webhook: proc { |pm| m = pm.media; m.current_team.setting(:slack_webhook) }

  notifies_pusher on: :create,
                  event: 'media_added',
                  target: proc { |pm| pm.project },
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
end
