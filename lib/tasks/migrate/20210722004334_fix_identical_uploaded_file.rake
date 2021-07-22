namespace :check do
  namespace :migrate do
    task fix_identical_uploaded_file: :environment do
      last_id = Rails.cache.read('check:migrate:fix_identical_uploaded_file:last_id')
      raise "No last_id found in cache for check:fix_identical_uploaded_file! Aborting." if last_id.nil?

      started = Time.now.to_i
      duplicated_media_ids = []
      updated_pms = 0
      total = Media.where(type: ['UploadedAudio', 'UploadedVideo', 'UploadedImage']).where("file ~* ?", '[0-9a-f]{32}\.').where("id <= ? ", last_id).group(:file).having('count(*) > 1').count.size
      progressbar = ProgressBar.create(:title => "Fix identical uploaded files", :total => total)
      medias = Media.select('file, MIN(medias.id) AS min_id').where(type: ['UploadedAudio', 'UploadedVideo', 'UploadedImage']).where("file ~* ?", '[0-9a-f]{32}\.').where("id <= ? ", last_id).group(:file).having('count(*) > 1').each do |media|
        progressbar.increment
        pms = ProjectMedia.select(:id, :media_id).joins(:media).where('medias.file = ? AND medias.id != ?', media.file, media.min_id)
        duplicated_media_ids += pms.map(&:media_id)
        ProjectMedia.where(id: pms.map(&:id)).update_all(media_id: media.min_id)
        updated_pms += pms.size
      end
      Media.where(id: duplicated_media_ids).delete_all
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
      puts "Updated #{updated_pms} project medias"
      puts "Deleted #{duplicated_media_ids.size} medias"
    end
  end
end
