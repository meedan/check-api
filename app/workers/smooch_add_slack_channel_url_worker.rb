class SmoochAddSlackChannelUrlWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'smooch'

  def perform(id, fields)
    a = Dynamic.where(id: id, annotation_type: 'smooch_user').last
    unless a.nil?
      a.set_fields = fields
      a.skip_check_ability = true
      a.skip_notifications = true
      a.save!
    end
  end
end
