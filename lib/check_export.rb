module CheckExport
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
    pm.get_project_media_status
  end

  def export_project_media_annotations(pm)
    pm.get_annotations('comment').to_enum.reverse_each.with_index.collect{ |c,i| Hash[
      "note_date_#{i+1}": c.created_at,
      "note_user_#{i+1}": c.annotator.name,
      "note_content_#{i+1}": c.data['text']
    ]}.reduce({}){ |h,o| h.merge(o) }
    .merge(
      pm.get_annotations('task').map(&:load).to_enum.reverse_each.with_index.collect do |t, i|
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
    ).merge(
      pm.get_annotations('translation').map(&:load).to_enum.reverse_each.with_index.collect{ |t,i| Hash[
        "translation_text_#{i+1}": t.get_field('translation_text')&.value,
        "translation_language_#{i+1}": t.get_field('translation_language')&.value,
        "translation_note_#{i+1}": t.get_field('translation_note')&.value,
      ]}.reduce({}){ |h,o| h.merge(o) }
    )
  end

  def export_csv
    hashes = self.export
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

  def export_images
    require 'open-uri'
    output = {}
    ProjectMedia.joins(:media).where('medias.type' => 'UploadedImage', 'project_id' => self.id).find_each do |pm|
      path = pm.media.file.path
      key = [self.team.slug, self.title.parameterize, pm.id].join('_') + File.extname(path)
      output[key] = File.read(path)
    end
    ProjectMedia.joins(:media).where('medias.type' => 'Link', 'project_id' => self.id).find_each do |pm|
      key = [self.team.slug, self.title.parameterize, pm.id, 'screenshot'].join('_') + '.png'
      begin
        screenshot_url = JSON.parse(pm.get_annotations('pender_archive').last.get_fields.select{ |f| f.field_name == 'pender_archive_response' }.last.value)['screenshot_url'].gsub(CONFIG['pender_url'], CONFIG['pender_url_private'])
        output[key] = open(screenshot_url).read
      rescue
        output[key] = nil
      end
    end
    output
  end

  def export_zip(type)
    require 'zip'
    contents = self.send("export_#{type}")
    self.export_password = SecureRandom.hex
    buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), Zip::TraditionalEncrypter.new(self.export_password)) do |out|
      contents.each do |filename, content|
        next if content.nil?
        out.put_next_entry(filename)
        out.write content
      end
    end
    buffer.rewind
    File.write(self.export_filepath(type), buffer.read)
  end

  def export_password
    @export_password
  end

  def export_password=(password)
    @export_password = password
  end

  def export_filename(type)
    basename = [self.team.slug, self.title.parameterize, self.created_at.to_i.to_s, type].join('_')
    basename = basename + '_' + Digest::MD5.hexdigest(basename).reverse
    @basename ||= basename
  end

  def export_filepath(type)
    dir = File.join(Rails.root, 'public', 'project_export')
    Dir.mkdir(dir) unless File.exist?(dir)
    File.join(dir, self.export_filename(type) + '.zip')
  end

  def export_to_csv_in_background(user = nil)
    self.export_project_in_background(:csv, user)
  end

  def export_images_in_background(user = nil)
    self.export_project_in_background(:images, user)
  end

  def export_project_in_background(type, user = nil)
    email = user.nil? ? nil : user.email
    self.class.delay_for(1.second).export_project(type, self.class.name, self.id, email)
  end

  module ClassMethods
    def export_project(type, klass, id, email)
      obj = klass.constantize.find(id)
      obj.export_zip(type)
      AdminMailer.delay.send_download_link(type, obj, email, obj.export_password) unless email.blank?
      days = CONFIG['export_download_expiration_days'] || 7
      klass.constantize.delay_for(days.to_i.days).remove_export_file(obj.export_filepath(type))
    end

    def remove_export_file(filepath)
      Rails.logger.info "File #{filepath} was removed"
      FileUtils.rm_f(filepath)
    end
  end
end
