# bundle exec rake check:data:statistics[workspace_slugs_as_a_dot_separated_values_string]
require 'open-uri'
include ActionView::Helpers::DateHelper

namespace :check do
  namespace :data do
    desc 'Generate statistics about workspaces with active tiplines'
    task statistics: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      slugs = params.to_a.first.to_s.split('.')
      if slugs.empty? || Team.where(slug: slugs).empty?
        puts 'Please provide a list of workspace slugs'
      else
        current_date = DateTime.now

        slugs.each do |slug|
          team = Team.find_by_slug(slug)
          next if ProjectMedia.where(team_id: team.id, user_id: BotUser.smooch_user.id).count == 0

          historic_rows = Rails.cache.fetch("data:report:#{team.id}") do
            # Regenerate data from previous months
            first_media_date = ProjectMedia.where(team_id: team.id, user_id: BotUser.smooch_user.id).order('created_at ASC').first.created_at.beginning_of_day
            iteration_date = first_media_date
            rows = []
            begin
              rows += CheckStatistics.get_team_statistics_for_month(iteration_date, team)
              iteration_date += 1.month
            end while iteration_date < current_date.beginning_of_month
            rows
          end
          # Remove outdated data from cache
          current_month_rows = CheckStatistics.get_team_statistics_for_month(current_date, team)
          invalidated_keys = current_month_rows.map{|r| r["ID"] }
          historic_rows.reject!{|r| invalidated_keys.include?(r["ID"]) }

          CheckStatistics.cache_team_data(team, historic_rows + current_month_rows)
        end
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
