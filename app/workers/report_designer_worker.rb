class ReportDesignerWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch', retry: 3
  sidekiq_retries_exhausted { |msg| retry_callback(msg) }

  def self.retry_callback(msg)
    id = msg['args'].first
    d = Dynamic.find(id)
    d.set_fields = d.data.merge({ last_error: "[#{Time.now}] #{msg['error_message']}" }).to_json
    d.save!
  end

  def perform(id, action)
    d = Dynamic.where(id: id).last
    return if d.nil?
    d.report_image_generate_png(true) if d.get_field_value('use_visual_card')
    pm = ProjectMedia.where(id: d.annotated_id).last
    ::Bot::Smooch.send_report_to_users(pm, action) unless pm.nil?
    d.set_fields = d.data.merge({
      last_published: Time.now.to_i.to_s,
      previous_published_status_label: d.get_field_value('status_label').to_s
    }).to_json
    d.save!
  end
end
