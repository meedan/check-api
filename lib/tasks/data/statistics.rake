require 'open-uri'
include ActionView::Helpers::DateHelper

module Check::Statistics
  class ArgumentError < ::ArgumentError; end
  class CalculationError < ::StandardError; end
  class IncompleteRunError < ::StandardError; end
end

namespace :check do
  namespace :data do
    # bundle exec rake check:data:statistics
    desc 'Generate ongoing monthly statistics for all workspaces'
    task :statistics, [:ignore_convo_cutoff] => [:environment] do |_t, args|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      errors = []
      team_ids = Team.joins(:project_medias).where(project_medias: { user: BotUser.pluck(:id) }).distinct.pluck(:id)
      current_time = DateTime.now
      puts "[#{Time.now}] Detected #{team_ids.length} teams with tipline data"
      team_ids.each_with_index do |team_id, index|
        TeamBotInstallation.where(team_id: team_id, user: BotUser.pluck(:id)).find_each do |bot|
          tipline_message_statistics = Check::TiplineMessageStatistics.new(team_id)
          date = ProjectMedia.where(team_id: team_id, user: bot.user).order('created_at ASC').first&.created_at&.beginning_of_day

          next if date.nil?

          team = Team.find(team_id)
          languages = team.get_languages.to_a
          platforms = bot.user == BotUser.smooch_user ? bot.smooch_enabled_integrations.keys : Bot::Smooch::SUPPORTED_INTEGRATION_NAMES.keys

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
                begin
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

                  # Check if any statistics are non-zero
                  if row_attributes.values.any? { |value| value != 0 }
                    partial_month = MonthlyTeamStatistic.find_by(team_id: team_id, platform: platform, language: language, start_date: month_start)
                    if partial_month.present?
                      partial_month.update!(row_attributes.merge!(team_id: team_id))
                      team_stats[:updated] += 1
                    else
                      MonthlyTeamStatistic.create!(row_attributes.merge!(team_id: team_id))
                      team_stats[:created] += 1
                    end
                  else
                    team_stats[:skipped_zero] += 1
                  end

                rescue StandardError => e
                  error = Check::Statistics::CalculationError.new(e)
                  errors.push(error)
                  puts "Error #{error}"
                  CheckSentry.notify(error, team_id: team_id, platform: platform, language: language, start_date: month_start, end_date: period_end)
                  team_stats[:errored] += 1
                end
              end
            end
            date += 1.month
          # Protect against generating stats for the future, by bailing if start of the start of first day of month is later than time rake task was run
          end while date.beginning_of_month <= current_time

          puts "[#{Time.now}] Stats summary for team with ID #{team_id} : #{team_stats.map{|k,v| "#{k} - #{v}" }.join("; ") }. Platforms: #{platforms.join(',')}. Languages: #{languages.join(', ')}"
        end
      end

      ActiveRecord::Base.logger = old_logger
      raise Check::Statistics::IncompleteRunError.new("Failed to calculate #{errors.length} monthly team statistics") if errors.any?
    end

    # bundle exec rake check:data:regenerate_statistics[start_date]
    desc 'Regenerate all historic statistics for all workspaces from a given start date'
    task :regenerate_statistics, [:start_date] => [:environment] do |_t, args|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      start_date = DateTime.parse(args.start_date) rescue nil
      if start_date.nil?
        $stderr.puts "Invalid or missing start_date argument"
        raise Check::Statistics::ArgumentError.new("Invalid or missing start_date argument")
      end

      puts "[#{Time.now}] Starting to regenerate all statistics from #{start_date}"
      begin
        supported_stats = %w(
          unique_newsletters_sent
        )

        puts "[#{Time.now}] Regenerating stats for the following keys: #{supported_stats}. Total to update: #{MonthlyTeamStatistic.where('start_date >= ?', start_date).count}"

        total_successful = Hash.new(0)
        MonthlyTeamStatistic.where('start_date >= ?', start_date).find_each do |monthly_stats|
          team_id = monthly_stats.team_id
          start_date = monthly_stats.start_date
          end_date = monthly_stats.end_date
          language = monthly_stats.language

          begin
            supported_stats.each do |stat|
              method_name = :number_of_newsletters_sent
              result = CheckStatistics.send(method_name, team_id, start_date, end_date, language)
              monthly_stats.update!(stat => result)
              total_successful[stat.to_sym] += 1
            end
          rescue StandardError => e
            $stderr.puts "[#{Time.now}] Failed to update MonthlyTeamStatistic with ID #{monthly_stats.id}. Error: #{e}"
            next
          end
        end
        puts "[#{Time.now}] Finished updating MonthlyTeamStatistics. Total updated: #{total_successful}"
      rescue StandardError => e
        $stderr.puts e
      ensure
        ActiveRecord::Base.logger = old_logger
      end
    end
  end
end
