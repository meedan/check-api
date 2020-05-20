class ReportDesignerWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch', retry: 3
  sidekiq_retry_in { |_count, _e| retry_in_callback }
  sidekiq_retries_exhausted { |msg, e| retries_exhausted_callback(msg, e) }

  def self.retry_in_callback
    1
  end

  def self.retries_exhausted_callback(msg, e)
    id = msg['args'].first
    d = Dynamic.find(id)
    d.set_fields = d.data.merge({ last_error: "[#{Time.now}] #{msg['error_message']}" }).to_json
    d.save!
    ::Bot::Smooch.notify_error(e, { method: 'ReportDesignerWorker::retries_exhausted_callback', dynamic_annotation_id: id, error_message: msg['error_message'] }, RequestStore[:request])
  end

  def perform(id, action)
    d = Dynamic.where(id: id).last
    return if d.nil?
    d.report_image_generate_png if d.get_field_value('use_visual_card')
    pm = ProjectMedia.where(id: d.annotated_id).last
    ::Bot::Smooch.send_report_to_users(pm, action) unless pm.nil?
    d.set_fields = d.data.merge({
      last_published: Time.now.to_i.to_s,
      previous_published_status_label: d.get_field_value('status_label').to_s
    }).to_json
    d.save!
    pm.clear_caches
  end
end
