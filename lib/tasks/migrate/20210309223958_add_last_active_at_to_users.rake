namespace :check do
  namespace :migrate do
    task add_last_active_at_to_users: :environment do
      last_id = Rails.cache.read('check:migrate:add_last_active_at_to_users:last_id')
last_id = User.last.id
      raise "No last_id found in cache for check:migrate:add_last_active_at_to_users! Aborting." if last_id.nil?

      started = Time.now.to_i
      total = User.where('id <= ?', last_id).count
      puts "[#{Time.now}] Set column last_active_at with value from last_sign_in_at on #{total} Users"
      i = 0
      User.where('id <= ?', last_id).find_each do |user|
        user.update_column(:last_active_at, user.last_sign_in_at)
        i += 1
        puts "(#{i}/#{total}) [#{Time.now}]"
      end

      seconds = ((Time.now.to_i - started)).to_i
      puts "[#{Time.now}] Done"
      puts "#{total} users updated in #{seconds} seconds."
      Rails.cache.delete('check:migrate:add_last_active_at_to_users:last_id')
    end
  end
end
