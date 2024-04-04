namespace :check do
  namespace :migrate do
    task migrate_media_uuid: :environment do
      started = Time.now.to_i
      # Media of type Claim
      last_claim_id = Rails.cache.read('check:migrate:migrate_media_uuid:claim_id') || 0
      Media.where(type: 'Claim').where('id > ?', last_claim_id).find_in_batches(batch_size: 2000) do |medias|
        medias.each do |m|
          print '.'
          uuid = Media.where(type: 'Claim', quote: m.quote.to_s.strip).joins("INNER JOIN project_medias pm ON pm.media_id = medias.id").first&.id
          uuid ||= self.id
          m.update_column(:uuid, uuid)
        end
        last_id = medias.map(&:id).max
        Rails.cache.write('check:migrate:migrate_media_uuid:claim_id', last_id)
      end
      # Other medias (link, image, audio, etc)
      Media.where.not(type: 'Claim').find_in_batches(batch_size: 2000) do |medias|
        medias.each do |m|
          print '.'
          m.update_column(:uuid, m.id)
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end