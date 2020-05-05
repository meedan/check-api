module CheckExport
  def self.included(base)
    base.extend(ClassMethods)
  end

  def export(last_id = 0, annotation_types = ['comment', 'task'])
    self.project_medias.order(:id).find_each(start: last_id + 1).collect{ |pm| Hash[
      project_id: pm.project_id,
      report_id: pm.id,
      report_title: pm.title,
      report_url: pm.full_url,
      report_date: pm.created_at,
      media_content: pm.media_content,
      media_url: pm.media.media_url,
      report_status: self.get_project_media_status(pm),
      report_author: pm.user&.name,
      time_delta_to_first_status: pm.time_to_status(:first),
      time_delta_to_last_status: pm.time_to_status(:last),
      time_original_media_publishing: pm.media.original_published_time,
      type: pm.media.media_type,
      contributing_users: pm.contributing_users_count,
      tags: pm.tags_list
    ].merge(
      self.export_annotations_count(pm, annotation_types)
    ).merge(
      self.export_project_media_annotations
    )}
  end

  def get_project_media_status(pm)
    pm.get_project_media_status
  end

  def export_project_media_annotations
    @annotations.where(annotation_type: 'language').map(&:load).collect{ |l| Hash[
      language: l.get_field_value('language')
    ]}.reduce({}){ |h,o| h.merge(o) }
    .merge(
      @annotations.where(annotation_type: 'comment').to_enum.reverse_each.with_index.collect{ |c,i| Hash[
        "note_date_#{i+1}": c.created_at,
        "note_user_#{i+1}": c.annotator.name,
        "note_content_#{i+1}": c.data['text']
      ]}.reduce({}){ |h,o| h.merge(o) }
    ).merge(
      @annotations.where(annotation_type: 'task').map(&:load).to_enum.reverse_each.with_index.collect do |t, i|
        task_hash = {
          "task_#{i+1}_question": t.label
        }
        t.responses.map(&:load).each_with_index do |r, j|
          task_hash.merge!({
            "task_#{i+1}_answer_#{j+1}_user": r&.annotator&.name,
            "task_#{i+1}_answer_#{j+1}_date": r&.created_at,
            "task_#{i+1}_answer_#{j+1}_content": r&.values(['response'], '')&.dig('response'),
            "task_#{i+1}_answer_#{j+1}_note": r&.values(['note'], '')&.dig('note')
          })
        end
        task_hash
      end.reduce({}){ |h,o| h.merge(o) }
    )
  end

  def export_annotations_count(pm, annotation_types)
    @annotations = pm.get_annotations(annotation_types)
    annotations_count = {}
    return annotations_count unless annotation_types.is_a?(Array)
    annotation_types.each do |type|
      annotations_count.merge!(self.send("export_#{type}_count", pm)) if self.respond_to?("export_#{type}_count")
    end
    annotations_count
  end

  def export_comment_count(_pm)
    {
      notes_ugc_count: @annotations.where(annotation_type: 'comment').count
    }
  end

  def export_task_count(pm)
    {
      tasks_count: @annotations.where(annotation_type: 'task').count,
      tasks_resolved_count: pm.completed_tasks_count
    }
  end

  def export_smooch_count(_pm)
    { number_of_requests: @annotations.where(annotation_type: 'smooch').count }
  end

  def export_smooch_response_count(_pm)
    { responses_with_final_status_count: @annotations.where(annotation_type: 'smooch_response').count }
  end

  def export_csv(last_id = 0, annotation_types = ['comment', 'task'])
    hashes = self.export(last_id, annotation_types)
    headers = hashes.inject([]) {|res, h| res | h.keys}
    content = CSV.generate do |csv|
      csv << headers
      hashes.each do |x|
        csv << headers.map {|header| x[header] || ""}
      end
    end
    key = [self.team.slug, self.title.parameterize, Time.now.to_i.to_s].join('_') + '.csv'
    { key => content }
  end

  def export_images(last_id = 0, _annotation_types = [])
    require 'open-uri'
    output = {}
    ProjectMedia.order(:id).joins(:media).where('medias.type' => 'UploadedImage', 'project_id' => self.id).find_each(start: last_id + 1) do |pm|
      path = pm.media.picture
      key = [self.team.slug, self.title.parameterize, pm.id].join('_') + File.extname(path)
      output[key] = open(path).read
    end
    ProjectMedia.order(:id).joins(:media).where('medias.type' => 'Link', 'project_id' => self.id).find_each(start: last_id + 1) do |pm|
      key = [self.team.slug, self.title.parameterize, pm.id, 'screenshot'].join('_') + '.png'
      begin
        screenshot_url = JSON.parse(pm.get_annotations('archiver').last.get_fields.select{ |f| f.field_name == 'pender_archive_response' }.last.value)['screenshot_url'].gsub(CONFIG['pender_url'], CONFIG['pender_url_private'])
        output[key] = open(screenshot_url).read
      rescue
        output[key] = nil
      end
    end
    output
  end

  def export_zip(type, last_id = 0, annotation_types = ['comment', 'task'])
    require 'zip'
    contents = self.send("export_#{type}", last_id, annotation_types)
    self.export_password = SecureRandom.hex
    buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), Zip::TraditionalEncrypter.new(self.export_password)) do |out|
      contents.each do |filename, content|
        next if content.nil?
        out.put_next_entry(filename)
        out.write content
      end
    end
    buffer.rewind
    CheckS3.write(self.export_filepath(type), 'application/zip', buffer.read)
  end

  def export_password
    @export_password
  end

  def export_password=(password)
    @export_password = password
  end

  def export_filename(type)
    basename = [self.team.slug, self.title.parameterize, Time.now.to_i.to_s, type].join('_')
    basename = basename + '_' + Digest::MD5.hexdigest(basename).reverse
    @basename ||= basename
  end

  def export_filepath(type)
    'project_export/' + self.export_filename(type) + '.zip'
  end

  def export_to_csv_in_background(user = nil, last_id = 0)
    self.export_project_in_background(:csv, user, last_id)
  end

  def export_images_in_background(user = nil, last_id = 0)
    self.export_project_in_background(:images, user, last_id)
  end

  def export_project_in_background(type, user = nil, last_id = 0)
    email = user.nil? ? nil : user.email
    self.class.delay_for(1.second).export_project(type, self.class.name, self.id, email, last_id)
  end

  module ClassMethods
    def export_project(type, klass, id, email, last_id = 0, annotation_types = ['comment', 'task'])
      obj = klass.constantize.find(id)
      obj.export_zip(type, last_id, annotation_types)
      link = CheckS3.public_url(obj.export_filepath(type))
      AdminMailer.delay.send_download_link(type, obj, link, email, obj.export_password) unless email.blank?
      days = CONFIG['export_download_expiration_days'] || 7
      klass.constantize.delay_for(days.to_i.days).remove_export_file(obj.export_filepath(type))
    end

    def remove_export_file(filepath)
      CheckS3.delete(filepath)
      Rails.logger.info "[Data Import/Export] File #{filepath} was removed"
    end
  end
end
