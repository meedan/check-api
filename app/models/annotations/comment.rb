class Comment
  include AnnotationBase

  attribute :text, String, presence: true
  validates_presence_of :text

  notifies_slack on: :save,
                 if: proc { |c| c.current_user.present? && c.current_team.present? && c.current_team.setting(:slack_notifications_enabled).to_i === 1 && c.annotated_type === 'Media' },
                 message: proc { |c| "<#{c.origin}/user/#{c.current_user.id}|*#{c.current_user.name}*> added a note on <#{c.origin}/project/#{c.context_id}/media/#{c.annotated_id}|#{c.annotated.data['title']}>: <#{c.origin}/project/#{c.context_id}/media/#{c.annotated_id}#annotation-#{c.dbid}|\"#{c.text}\">" },
                 channel: proc { |c| c.context.setting(:slack_channel) || c.current_team.setting(:slack_channel) },
                 webhook: proc { |c| c.current_team.setting(:slack_webhook) }

  def content
    { text: self.text }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

end
