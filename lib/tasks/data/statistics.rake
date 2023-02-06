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
      current_time = Time.now
      puts "[#{Time.now}] Detected #{team_ids.length} teams with tipline data"
      team_ids.each_with_index do |team_id, index|
        tipline_bot = TeamBotInstallation.where(team_id: team_id, user: BotUser.smooch_user).last
        if tipline_bot.nil?
          puts "[#{Time.now}] No tipline bot installed for team #{team_id}; skipping team"
          next
        end

        date = ProjectMedia.where(team_id: team_id, user: BotUser.smooch_user).order('created_at ASC').first&.created_at&.beginning_of_day
        team = Team.find(team_id)
        languages = team.get_languages.to_a
        platforms = tipline_bot.smooch_enabled_integrations.keys

        team_stats = Hash.new(0)
        puts "[#{Time.now}] Generating month tipline statistics for team with ID #{team_id}. (#{index + 1} / #{team_ids.length})"
        begin
          month_start = date.beginning_of_month
          month_end = date.end_of_month

          platforms.each do |platform|
            languages.each do |language|
              if MonthlyTeamStatistic.where(team_id: team_id, platform: platform, language: language, start_date: month_start, end_date: month_end).any?
                team_stats[:skipped] += 1
                next
              end

              period_end = current_time < month_end ? current_time : month_end
              row_attributes = CheckStatistics.get_statistics(month_start.to_date, period_end, team_id, platform, language)

              partial_month = MonthlyTeamStatistic.find_by(team_id: team_id, platform: platform, language: language, start_date: month_start)
              if partial_month.present?
                team_stats[:updated] += 1
                partial_month.update!(row_attributes.merge!(team_id: team_id))
              else
                team_stats[:created] += 1
                MonthlyTeamStatistic.create!(row_attributes.merge!(team_id: team_id))
              end
            end
          end
          date += 1.month
        # Protect against generating stats for the future, by bailing if start of the start of first day of month is later than time rake task was run
        end while date.beginning_of_month <= current_time

        puts "[#{Time.now}] Stats summary for team with ID #{team_id}: #{team_stats.map{|k,v| "#{k} - #{v}" }.join("; ") }. Platforms: #{platforms.join(',')}. Languages: #{languages.join(', ')}"
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
