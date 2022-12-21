# bundle exec rake check:data:statistics[workspace_slugs_as_a_dot_separated_values_string]

require 'open-uri'
include ActionView::Helpers::DateHelper

namespace :check do
  namespace :data do
    desc 'Generate some statistics about some workspaces'
    task statistics: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      slugs = params.to_a.first.to_s.split('.')
      if slugs.empty? || Team.where(slug: slugs).empty?
        puts 'Please provide a list of workspace slugs'
      else
        filename = "tipline-statistics-month"
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

        slugs.each do |slug|
          team = Team.find_by_slug(slug)
          next if ProjectMedia.where(team_id: team.id, user_id: BotUser.smooch_user.id).count == 0
          team_rows = []
          date = nil
          begin
            date = ProjectMedia.where(team_id: team.id, user_id: BotUser.smooch_user.id).order('id ASC').first.created_at.beginning_of_day if date.nil?
            from = date.beginning_of_month
            to = date.end_of_month
            puts "[#{Time.now}] Generating month tipline statistics for #{team.name} (#{from})"
            TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
              team.get_languages.each do |language|
                team_rows << CheckStatistics.get_statistics(from, to, slug, platform, language)
              end
            end
            date += 1.month
          end while date <= Time.now
          CheckStatistics.cache_team_data(team, header, team_rows)
        end
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
