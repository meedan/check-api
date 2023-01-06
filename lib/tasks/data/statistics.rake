# bundle exec rake check:data:statistics

require 'open-uri'
include ActionView::Helpers::DateHelper

namespace :check do
  namespace :data do
    desc 'Generate some statistics about some workspaces'
    task statistics: :environment do |_t|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      team_ids = Team.joins(:project_medias).where(project_medias: { user: BotUser.smooch_user }).distinct.pluck(:id)
      puts "[#{Time.now}] Detected #{team_ids.length} teams with tipline data"
      header = [
        'ID',
        'Org',
        'Platform',
        'Language',
        'Month',
        'Conversations',
        'Average number of conversations per day',
        'Number of messages sent',
        'Average messages per day',
        'Unique users',
        'Returning users',
        'Searches',
        'Positive searches',
        'Negative searches',
        'Search feedback positive',
        'Search feedback negative',
        'Search no feedback',
        'Valid new requests',
        'Published native reports',
        'Published imported reports',
        'Requests answered with a report',
        'Reports sent to users',
        'Unique users who received a report',
        'Average (median) response time',
        'Unique newsletters sent',
        'New newsletter subscriptions',
        'Newsletter cancellations',
        'Current subscribers'
      ]

      team_ids.each_with_index do |team_id, index|
        team_rows = []
        date = nil
        begin
          team = Team.find(team_id)
          date = ProjectMedia.where(team: team, user: BotUser.smooch_user).order('id ASC').first.created_at.beginning_of_day if date.nil?
          from = date.beginning_of_month
          to = date.end_of_month
          puts "[#{Time.now}] Generating month tipline statistics for #{team.name} (#{from}). (#{index + 1} / #{team_ids.length})"
          TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
            team.get_languages.each do |language|
              team_rows << CheckStatistics.get_statistics(from, to, team.slug, platform, language)
            end
          end
          date += 1.month
        end while date <= Time.now
        CheckStatistics.cache_team_data(team, header, team_rows)
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
