# bundle exec rake check:data:statistics[start_year,start_month,end_year (0 = current year),end_month (0 = current month),group_by_month (0 = no grouping or 1 = grouping),workspace_slugs_as_a_dot_separated_values_string]

require 'open-uri'
include ActionView::Helpers::DateHelper

def requests(slug, platform, start_date, end_date, language)
  Annotation
    .where(annotation_type: 'smooch')
    .joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_data'")
    .where("value_json->'source'->>'type' = ?", platform)
    .where("value_json->>'language' = ?", language)
    .where('t.slug' => slug)
    .where('annotations.created_at' => start_date..end_date)
end

def reports_received(slug, platform, start_date, end_date, language)
  DynamicAnnotation::Field
    .where(field_name: 'smooch_report_received')
    .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = a.id AND fs.field_name = 'smooch_data'")
    .where('t.slug' => slug)
    .where("fs.value_json->'source'->>'type' = ?", platform)
    .where("fs.value_json->>'language' = ?", language)
    .where('dynamic_annotation_fields.created_at' => start_date..end_date)
end

def project_media_requests(slug, platform, start_date, end_date, language)
  base = requests(slug, platform, start_date, end_date, language)
  base.joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id")
end

def team_requests(slug, platform, start_date, end_date, language)
  base = requests(slug, platform, start_date, end_date, language)
  base.joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id")
end

def get_statistics(start_date, end_date, slug, platform, language)
  platform_name = Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform]
  month = nil
  if start_date.month != end_date.month || start_date.year != end_date.year
    month = "#{Date::MONTHNAMES[start_date.month]} #{start_date.year} - #{Date::MONTHNAMES[end_date.month]} #{end_date.year}"
  else
    month = "#{Date::MONTHNAMES[start_date.month]} #{start_date.year}"
  end
  data = [Team.find_by_slug(slug).name, platform_name, language, month]

  # Number of conversations
  value1 = project_media_requests(slug, platform, start_date, end_date, language).count
  value2 = team_requests(slug, platform, start_date, end_date, language).count
  data << (value1 + value2).to_s

  # Average number of end-user messages per day
  numbers_of_messages = []
  project_media_requests(slug, platform, start_date, end_date, language).find_each do |a|
    numbers_of_messages << JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
  end
  team_requests(slug, platform, start_date, end_date, language).find_each do |a|
    numbers_of_messages << JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
  end
  if numbers_of_messages.size == 0
    data << 0
  else
    data << (numbers_of_messages.sum / (start_date.to_date..end_date.to_date).count).to_i
  end
  
  # Number of unique users
  uids = []
  project_media_requests(slug, platform, start_date, end_date, language).find_each do |a|
    uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
    uids << uid if !uid.nil? && !uids.include?(uid)
  end
  team_requests(slug, platform, start_date, end_date, language).find_each do |a|
    uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
    uids << uid if !uid.nil? && !uids.include?(uid)
  end
  data << uids.size

  # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
  data << DynamicAnnotation::Field.where(field_name: 'smooch_data', created_at: start_date.ago(2.months)..start_date).where("value_json->>'authorId' IN (?) AND value_json->>'language' = ?", uids, language).collect{ |f| f.value_json['authorId'] }.uniq.size

  # Number of valid queries
  data << project_media_requests(slug, platform, start_date, end_date, language).where('pm.archived' => 0).count.to_s

  # Number of new published reports created in Check (e.g., not imported)
  # NOTE: For all platforms
  data << Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).where("data LIKE '%language: #{language}%'").where.not('pm.user_id' => BotUser.fetch_user.id).count.to_s

  # Number of queries answered with a report
  data << reports_received(slug, platform, start_date, end_date, language).group('pm.id').count.size.to_s

  # Number of reports sent to users
  data << reports_received(slug, platform, start_date, end_date, language).count.to_s

  # Number of unique users who received a report
  data << reports_received(slug, platform, start_date, end_date, language).collect{ |f| JSON.parse(f.annotation.load.get_field_value('smooch_data'))['authorId'] }.uniq.size

  # Average time to publishing
  times = []
  reports_received(slug, platform, start_date, end_date, language).find_each do |f|
    times << (f.created_at - f.annotation.created_at)
  end
  if times.size == 0
    # data << 0
    data << '-'
  else
    avg = times.sum.to_f / times.size
    # data << avg.to_i
    data << distance_of_time_in_words(avg)
  end

  # Number of new newsletter subscriptions
  data << TiplineSubscription.where(created_at: start_date..end_date, platform: platform_name, language: language).where('teams.slug' => slug).joins(:team).count.to_s

  # Number of newsletter subscription cancellations
  team = Team.find_by_slug(slug)
  data << Version.from_partition(team.id).where(created_at: start_date..end_date, team_id: team.id, item_type: 'TiplineSubscription', event_type: 'destroy_tiplinesubscription').where('object LIKE ?', "%#{platform_name}%").where('object LIKE ?', '%"language":"' + language + '"%').count.to_s

  # Current number of newsletter subscribers
  data << TiplineSubscription.where(created_at: start_date.ago(100.years)..end_date, platform: platform_name, language: language).where('teams.slug' => slug).joins(:team).count.to_s

  # Total number of imported reports
  # NOTE: For all languages and platforms
  data << ProjectMedia.joins(:team).where('teams.slug' => slug, 'created_at' => start_date..end_date, 'user_id' => BotUser.fetch_user.id).count.to_s

  # Number of published imported reports
  # NOTE: For all languages and platforms
  data << Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug, 'pm.user_id' => BotUser.fetch_user.id).where('annotations.created_at' => start_date..end_date).count.to_s

  puts data.join(',')
end

namespace :check do
  namespace :data do
    desc 'Generate some statistics about some workspaces'
    task statistics: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      args = params.to_a
      start_year = args[0].to_i
      start_month = args[1].to_i
      end_year = args[2].to_i
      end_year = Time.now.year if end_year == 0
      end_month = args[3].to_i
      end_month = Time.now.month if end_month == 0
      group_by_month = args[4].to_i
      slugs = args[5].to_s.split('.')
      if slugs.empty?
        puts 'Please provide a list of workspace slugs'
      else
        header = [
          'Org',
          'Platform',
          'Language',
          'Month',
          'Conversations',
          'Average messages per day',
          'Unique users',
          'Returning users',
          'Valid queries received (not in trash)',
          'New published reports (not imported)',
          'Queries answered with a report',
          'Reports sent to users',
          'Unique users who received a report',
          'Average (median) response time',
          'New newsletter subscriptions',
          'Newsletter cancellations',
          'Current subscribers',
          'Total imported reports',
          'Published imported reports'
        ]
        puts header.join(',')

        slugs.each do |slug|
          team = Team.find_by_slug(slug)
          TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
            team.get_languages.each do |language|
              if group_by_month == 1
                (start_year..end_year).to_a.each do |year|
                  year_start_month = 1
                  year_start_month = start_month if year == start_year
                  year_end_month = 12
                  year_end_month = end_month if year == end_year
                  (year_start_month..year_end_month).to_a.each do |month|
                    time = Time.parse("#{year}-#{month}-01")
                    next if team.created_at > time.end_of_month
                    get_statistics(time.beginning_of_month, time.end_of_month, slug, platform, language)
                  end
                end
              else
                get_statistics(Time.parse("#{start_year}-#{start_month}-01"), Time.parse("#{end_year}-#{end_month}-01").end_of_month, slug, platform, language)
              end
            end
          end
        end
      end
      ActiveRecord::Base.logger = old_logger
    end
  end
end
