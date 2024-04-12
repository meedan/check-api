namespace :check do
  namespace :migrate do
    def claim_uuid_for_duplicate_quote
      puts "Collect Claim uuid for duplicate quotes"
      claim_uuid = {}
      Claim.select('lower(quote) as quote, MIN(id) as first')
      .group('lower(quote)').having('COUNT(id) > 1')
      .each do |raw|
        claim_uuid[Digest::MD5.hexdigest(raw['quote'])] = raw['first']
      end
      claim_uuid
    end

    task migrate_media_uuid: :environment do
      started = Time.now.to_i
      # Media of type Claim
      claim_uuid = claim_uuid_for_duplicate_quote
      last_claim_id = Rails.cache.read('check:migrate:migrate_media_uuid:claim_id') || 0
      Claim.where('id > ?', last_claim_id).find_in_batches(batch_size: 2000) do |medias|
        m_items = []
        medias.each do |m|
          print '.'
          m.uuid = claim_uuid[Digest::MD5.hexdigest(m.quote.downcase)] || m.id
          m_items << m.attributes
        end
        Media.upsert_all(m_items)
        last_id = medias.map(&:id).max
        Rails.cache.write('check:migrate:migrate_media_uuid:claim_id', last_id)
      end
      # Other medias (link, image, audio, etc)
      Media.where.not(type: 'Claim').find_in_batches(batch_size: 2000) do |medias|
        m_items = []
        medias.each do |m|
          print '.'
          m.uuid = m.id
          m_items << m.attributes
        end
        Media.upsert_all(m_items)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
