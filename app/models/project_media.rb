class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media
  belongs_to :user

  after_create :set_search_context

  notifies_slack on: :create,
                 if: proc { |pm| m = pm.media; m.current_user.present? && m.current_team.present? && m.current_team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |pm| m = pm.media; data = m.data(pm.project); "<#{m.origin}/user/#{m.user.id}|*#{m.user.name}*> added an unverified link: <#{m.origin}/project/#{m.project_id}/media/#{m.id}|*#{data['title']}*>" },
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

  private

  def set_search_context
    em_context = self.media.annotations('embed', self.project).last unless self.project.nil?
    if em_context.nil?
      em_none = self.media.annotations('embed', 'none').last
      unless em_none.nil?
        em_none.search_context << self.project.id
        em_none.save!
      end
    end
  end

end
