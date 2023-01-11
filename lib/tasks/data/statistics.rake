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
      team_ids.each_with_index do |team_id, index|
        team = Team.find(team_id)
        team_rows = []
        date = nil
        begin
          date = ProjectMedia.where(team_id: team_id, user: BotUser.smooch_user).order('id ASC').first.created_at.beginning_of_day if date.nil?
          from = date.beginning_of_month
          to = date.end_of_month
          puts "[#{Time.now}] Generating month tipline statistics for team with ID #{team_id} (#{from}). (#{index + 1} / #{team_ids.length})"
          TeamBotInstallation.where(team_id: team_id, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
            team.get_languages.each do |language|
              row_attributes = CheckStatistics.get_statistics(from, to, team_id, platform, language)
              MonthlyTeamStatistic.create!(row_attributes.merge!(team: team))
            end
          end
          date += 1.month
        end while date <= Time.now
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
