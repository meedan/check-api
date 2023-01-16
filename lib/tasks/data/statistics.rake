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
        team = Team.find(team_id)
        team_rows = []
        date = ProjectMedia.where(team_id: team_id, user: BotUser.smooch_user).order('created_at ASC').first&.created_at&.beginning_of_day
        begin
          month_start = date.beginning_of_month
          month_end = date.end_of_month

          puts "[#{Time.now}] Generating month tipline statistics for team with ID #{team_id} (#{month_start}). (#{index + 1} / #{team_ids.length})"
          TeamBotInstallation.where(team_id: team_id, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
            team.get_languages.to_a.each do |language|
              # Complete month - skip
              next unless MonthlyTeamStatistic.where(team_id: team_id, platform: platform, language: language, start_date: month_start, end_date: month_end).blank?

              period_end = current_time < month_end ? current_time : month_end
              row_attributes = CheckStatistics.get_statistics(month_start, period_end, team_id, platform, language)

              partial_month = MonthlyTeamStatistic.find_by(team_id: team_id, platform: platform, language: language, start_date: month_start)
              if partial_month.present?
                # Partial month - update
                partial_month.update!(row_attributes.merge!(team: team))
              else
                # Empty month - create
                MonthlyTeamStatistic.create!(row_attributes.merge!(team: team))
              end
            end
          end
          date += 1.month
        end while date <= current_time
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
