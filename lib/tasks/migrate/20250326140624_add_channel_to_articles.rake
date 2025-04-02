# bundle exec rake check:migrate:add_channel_to_articles

namespace :check do
  namespace :migrate do
    desc 'Add channel to Articles(FactChecks and Explainers)'
    task add_channel_to_articles: :environment do
      ActiveRecord::Base.logger = nil

      def update_channel_for_query(query)
        count = query.count
        puts "[#{Time.now}] Number of instances to update channel to api: #{count}."
        i = 0
        query.in_batches(of: 1000) do |batch|
          i += 1
          batch.update_all(channel: 'api')
          puts "[#{Time.now}] Updated channel for batch ##{i}."
        end
        count
      end

      puts "[#{Time.now}] Starting to add channels to Articles"
      started = Time.now.to_i

      [FactCheck, Explainer].each do |model|
        query1 = model.joins(:author).where('users.type' => 'BotUser').where(channel: 'manual')
        count1 = update_channel_for_query(query1)
        query2 = model.joins(:user).where('users.type' => 'BotUser').where(author_id: nil).where(channel: 'manual')
        count2 = update_channel_for_query(query2)
        puts "[#{Time.now}] Updated channel for #{count1 + count2} instances of #{model}'s."
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
