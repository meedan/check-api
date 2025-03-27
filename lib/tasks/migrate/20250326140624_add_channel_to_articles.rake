# bundle exec rake check:migrate:add_channel_to_articles

namespace :check do
  namespace :migrate do
    desc 'Add channel to Articles(FactChecks and Explainers)'
    task add_channel_to_articles: :environment do
      puts "[#{Time.now}] Starting to add channels to Articles"
      started = Time.now.to_i
      TOTAL = []

      [FactCheck, Explainer].each do |model|
        query = model.joins(:user).where('users.type' => 'BotUser').where(channel: 'manual')
        TOTAL << query.count
        puts "[#{Time.now}] Total of instances of #{model} to update channel to api: #{query.count}."
  
        i = 0
        query.in_batches(of: 1000) do |batch|
          i += 1
          batch.update_all(channel: 'api')
          puts "[#{Time.now}] Updated channel for batch ##{i} of instances of model #{model}."
        end
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
      puts "Updated FactChecks: #{TOTAL.first}"
      puts "Updated Explainers: #{TOTAL.last}"
    end
  end
end
