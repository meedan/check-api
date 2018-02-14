module CheckCsvExport
  def self.included(base)
    base.extend(ClassMethods)
  end

  def export
    self.project_medias.collect{ |pm| Hash[
      project_id: pm.project_id,
      report_id: pm.id,
      report_title: pm.title,
      report_url: pm.full_url,
      report_date: pm.created_at,
      media_content: pm.media_content,
      media_url: pm.media.media_url,
      report_status: self.get_project_media_status(pm),
      report_author: pm.user.name,
      time_delta_to_first_status: pm.time_to_status(:first),
      time_delta_to_last_status: pm.time_to_status(:last),
      time_original_media_publishing: pm.media.original_published_time,
      type: pm.media.media_type,
      contributing_users: pm.contributing_users_count,
      tags: pm.tags_list,
      notes_count: pm.annotations.count,
      notes_ugc_count: pm.get_annotations('comment').count,
      tasks_count: pm.get_annotations('task').count,
      tasks_resolved_count: pm.tasks_resolved_count
    ].merge(
      self.export_project_media_annotations(pm)
    )}
  end

  def get_project_media_status(pm)
    CONFIG['app_name'] === 'Bridge' ?
      pm.get_annotations('translation_status').last.load.get_field('translation_status_status').value :
      pm.last_status
  end

  def export_project_media_annotations(pm)
    pm.get_annotations('comment').to_enum.reverse_each.with_index.collect{ |c,i| Hash[
      "note_date_#{i+1}": c.created_at,
      "note_user_#{i+1}": c.annotator.name,
      "note_content_#{i+1}": c.data['text']
    ]}.reduce({}){ |h,o| h.merge(o) }
    .merge(
      pm.get_annotations('task').map(&:load).to_enum.reverse_each.with_index.collect{ |t,i| r = t.responses.map(&:load).first; Hash[
        "task_question_#{i+1}": t.label,
        "task_user_#{i+1}": r&.annotator&.name,
        "task_date_#{i+1}": r&.created_at,
        "task_answer_#{i+1}": r&.values(['response'], '')&.dig('response'),
        "task_note_#{i+1}": r&.values(['note'], '')&.dig('note'),
      ]}.reduce({}){ |h,o| h.merge(o) }
    ).merge(
      pm.get_annotations('translation').map(&:load).to_enum.reverse_each.with_index.collect{ |t,i| Hash[
        "translation_text_#{i+1}": t.get_field('translation_text')&.value,
        "translation_language_#{i+1}": t.get_field('translation_language')&.value,
        "translation_note_#{i+1}": t.get_field('translation_note')&.value,
      ]}.reduce({}){ |h,o| h.merge(o) }
    )
  end

  def export_to_csv
    hashes = self.export
    headers = hashes.inject([]) {|res, h| res | h.keys}
    CSV.open(self.csv_filename, 'w+') do |csv|
      csv << headers
      hashes.each do |x|
        csv << headers.map {|header| x[header] || ""}
      end
    end
  end

  def csv_filename
    dir = File.join(Rails.root, 'public', 'project_export')
    Dir.mkdir(dir) unless File.exists?(dir)
    basename = [self.team.slug, self.title.parameterize, Time.now.to_i.to_s].join('_')
    File.join(dir, basename + '_' + Digest::MD5.hexdigest(basename).reverse + '.csv')
  end

  def export_to_csv_in_background(user = nil)
    email = user.nil? ? nil : user.email
    self.class.delay_for(1.second).export_to_csv(self.class.name, self.id, email)
  end

  module ClassMethods
    def export_to_csv(klass, id, email)
      obj = klass.constantize.find(id)
      obj.export_to_csv
      AdminMailer.delay.send_download_link(obj, email) unless email.blank?
      days = CONFIG['export_download_expiration_days'] || 7
      klass.constantize.delay_for(days.to_i.days).remove_csv_file(obj.csv_filename)
    end

    def remove_csv_file(filepath)
      Rails.logger.info "File #{filepath} was removed"
      FileUtils.rm_f(filepath)
    end
  end
end
