namespace :check do
  namespace :migrate do
    task migrate_last_received_terms_email_at: :environment do
      started = Time.now.to_i
      last_user_id = Rails.cache.read('check:migrate:migrate_last_received_terms_email_at:user_id') || 0
      User.where('id > ?', last_user_id).find_each do |user|
        print '.'
        user.update_columns(last_received_terms_email_at: user.last_accepted_terms_at)
        Rails.cache.write('check:migrate:migrate_last_received_terms_email_at:user_id', user.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
