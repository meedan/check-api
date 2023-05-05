require 'open-uri'
include ActionView::Helpers::DateHelper

module Check::Statistics
  class ArgumentError < ::ArgumentError; end
end

namespace :check do
  namespace :data do
    # bundle exec rake check:data:statistics
    desc 'Generate ongoing monthly statistics for all workspaces'
    task :statistics, [:ignore_convo_cutoff] => [:environment] do |_t, args|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      team_ids = Team.joins(:project_medias).where(project_medias: { user: BotUser.smooch_user }).distinct.pluck(:id)
      current_time = DateTime.now
      puts "[#{Time.now}] Detected #{team_ids.length} teams with tipline data"
      team_ids.each_with_index do |team_id, index|
        tipline_bot = TeamBotInstallation.where(team_id: team_id, user: BotUser.smooch_user).last
        if tipline_bot.nil?
          puts "[#{Time.now}] No tipline bot installed for team #{team_id}; skipping team"
          next
        end

        tipline_message_statistics = Check::TiplineMessageStatistics.new(team_id)
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
              tracing_attributes = { "app.team.id" => team_id, "app.attr.platform" => platform, "app.attr.language" => language}

              row_attributes = {}
              row_attributes = CheckStatistics.get_statistics(month_start.to_date, period_end, team_id, platform, language)

              # Start date for new conversation calculation, with optional override for testing
              if args.ignore_convo_cutoff || month_start >= DateTime.new(2023,4,1)
                CheckTracer.in_span("Check::TiplineMessageStatistics.monthly_conversations", attributes: tracing_attributes) do
                  row_attributes[:conversations_24hr] = tipline_message_statistics.monthly_conversations(
                    Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform],
                    language,
                    month_start,
                    period_end
                  )
                end
              end

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

    # bundle exec rake check:data:regenerate_statistics[unique_newsletters_sent]
    desc 'Regenerate specified historic statistic for all workspaces'
    task :regenerate_statistics, [:stats_to_generate] => [:environment] do |_t, args|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      puts "[#{Time.now}] Attempting to regenerate keys: #{args.stats_to_generate}"
      begin
        # Give user help if they want it
        supported_stats = %w(
          unique_newsletters_sent
        )

        # Make sure we have at least one valid argument
        requested_stats = (args.stats_to_generate || '').split(',').map(&:strip)
        valid_requested_stats = requested_stats.intersection(supported_stats)
        unless valid_requested_stats.length > 0
          raise Check::Statistics::ArgumentError.new("Argument '#{args.stats_to_generate}' is invalid. We currently support the following values passed a comma-separated list: #{supported_stats.join(',')}.")
        end

        puts "[#{Time.now}] Regenerating stats for the following keys: #{valid_requested_stats}. Total to update: #{MonthlyTeamStatistic.count}"

        # Update all of the stats
        total_successful = Hash.new(0)
        MonthlyTeamStatistic.find_each do |monthly_stats|
          team_id = monthly_stats.team_id
          start_date = monthly_stats.start_date
          end_date = monthly_stats.end_date
          language = monthly_stats.language

          begin
            if valid_requested_stats.include?('unique_newsletters_sent')
              monthly_stats.update!(unique_newsletters_sent: CheckStatistics.number_of_newsletters_sent(team_id, start_date, end_date, language))
              total_successful[:unique_newsletters_sent] += 1
            end
          rescue StandardError => e
            $stderr.puts "[#{Time.now}] Failed to update MonthlyTeamStatistic with ID #{monthly_stats.id}. Error: #{e}"
            next
          end
        end
        puts "[#{Time.now}] Finished updating MonthlyTeamStatistics. Total updated: #{total_successful}"
      rescue StandardError => e
        $stderr.puts e
        next
      ensure
        ActiveRecord::Base.logger = old_logger
      end
    end
  end
end
