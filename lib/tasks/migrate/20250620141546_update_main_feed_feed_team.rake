# bundle exec rake check:migrate:update_main_feed_feed_team

namespace :check do
  namespace :migrate do
    desc 'Update shared feed main feed\'s feed_team'
    task update_main_feed_feed_team: :environment do
      ActiveRecord::Base.logger = nil

      puts "[#{Time.now}] Starting to update main shared feed feed_team"
      started = Time.now.to_i

      # Find all main feeds
      FeedTeam.find_each do |feed_team|
        #  update only if the feed team is the main feed's feed_team
        feed = Feed.find(feed_team.feed_id)
        next unless feed_team.team_id == feed.team_id

        # Update media_saved_search and article_saved_search if they are present
        feed_team.media_saved_search = feed.media_saved_search.presence
        feed_team.article_saved_search = feed.article_saved_search.presence
        feed_team.save!
        puts "[#{Time.now}] Updated feed_team, #{feed_team.id},  for feed ID: #{feed.id}, Team ID: #{feed_team.team_id}."
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
