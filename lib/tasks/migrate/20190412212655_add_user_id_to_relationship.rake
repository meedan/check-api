namespace :check do
  namespace :migrate do
    task add_user_id_to_relationship: :environment do
      # Read the last annotation id we need to process that was set at migration time.
      last_id = Rails.cache.read('check:migrate:add_user_id_to_relationship:last_id')
      raise "No last_id found in cache for check:migrate:add_user_id_to_relationship! Aborting." if last_id.nil?

      # Get the user id from the paper trail and store it in the object itself.
      rel = PaperTrail::Version.where(item_type: 'Relationship').where('id < ?', last_id)
      n = rel.count
      i = 0
      rel.find_each do |v|
        i += 1
        puts "[#{Time.now}] (#{i}/#{n}) Migrating relationship #{v.item_id}"
        r = v.item
        next if r.nil?
        r.update_column(:user_id, v.whodunnit.to_i)
      end
    end
  end
end
