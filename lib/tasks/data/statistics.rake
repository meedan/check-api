# bundle exec rake check:data:statistics[year,start_month,end_month,group_by_month (0 or 1),workspace_slugs_as_a_dot_separated_values_string]

require 'open-uri'
include ActionView::Helpers::DateHelper

def requests(slug, platform, start_date, end_date)
  Annotation
    .where(annotation_type: 'smooch')
    .joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_data'")
    .where("value_json->'source'->>'type' = ?", platform)
    .where('t.slug' => slug)
    .where('annotations.created_at' => start_date..end_date)
end

def reports_received(slug, platform, start_date, end_date)
  DynamicAnnotation::Field
    .where(field_name: 'smooch_report_received')
    .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = a.id AND fs.field_name = 'smooch_data'")
    .where('t.slug' => slug)
    .where("fs.value_json->'source'->>'type' = ?", platform)
    .where('dynamic_annotation_fields.created_at' => start_date..end_date)
end

def project_media_requests(slug, platform, start_date, end_date)
  base = requests(slug, platform, start_date, end_date)
  base.joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id")
end

def team_requests(slug, platform, start_date, end_date)
  base = requests(slug, platform, start_date, end_date)
  base.joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id")
end

def get_statistics(start_date, end_date, slug, platform)
  platform_name = Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform]
  data = [Team.find_by_slug(slug).name, platform_name, start_date, end_date]

  # Number of conversations
  value1 = project_media_requests(slug, platform, start_date, end_date).count
  value2 = team_requests(slug, platform, start_date, end_date).count
  data << (value1 + value2).to_s
  
  # Number of unique users
  uids = []
  project_media_requests(slug, platform, start_date, end_date).find_each do |a|
    uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
    uids << uid if !uid.nil? && !uids.include?(uid)
  end
  team_requests(slug, platform, start_date, end_date).find_each do |a|
    uid = begin JSON.parse(a.load.get_field_value('smooch_data'))['authorId'] rescue nil end
    uids << uid if !uid.nil? && !uids.include?(uid)
  end
  data << uids.size

  # Number of valid queries
  data << project_media_requests(slug, platform, start_date, end_date).where('pm.archived' => 0).count.to_s

  # Number of new published reports
  # NOTE: For all platforms
  data << Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).count.to_s

  # Number of queries answered with a report
  data << reports_received(slug, platform, start_date, end_date).group('pm.id').count.size.to_s

  # Number of users who received a report
  data << reports_received(slug, platform, start_date, end_date).count.to_s

  # Number of new newsletter subscriptions
  data << TiplineSubscription.where(created_at: start_date..end_date, platform: platform_name).where('teams.slug' => slug).joins(:team).count.to_s

  # Number of newsletter subscription cancellations
  team = Team.find_by_slug(slug)
  data << Version.from_partition(team.id).where(created_at: start_date..end_date, team_id: team.id, item_type: 'TiplineSubscription', event_type: 'destroy_tiplinesubscription').where('object LIKE ?', "%#{platform_name}%").count.to_s

  # Average time to publishing
  times = []
  reports_received(slug, platform, start_date, end_date).find_each do |f|
    times << (f.created_at - f.annotation.created_at)
  end
  if times.size == 0
    data << 0
    data << '-'
  else
    avg = times.sum.to_f / times.size
    data << avg.to_i
    data << distance_of_time_in_words(avg)
  end

  # Average number of end-user messages per day
  numbers_of_messages = []
  project_media_requests(slug, platform, start_date, end_date).find_each do |a|
    numbers_of_messages << JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
  end
  team_requests(slug, platform, start_date, end_date).find_each do |a|
    numbers_of_messages << JSON.parse(a.load.get_field_value('smooch_data'))['text'].to_s.split(Bot::Smooch::MESSAGE_BOUNDARY).size
  end
  if numbers_of_messages.size == 0
    data << 0
  else
    data << (numbers_of_messages.sum / (start_date.to_date..end_date.to_date).count).to_i
  end
        
  # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
  data << DynamicAnnotation::Field.where(field_name: 'smooch_data', created_at: start_date.ago(2.months)..start_date).where("value_json->>'authorId' IN (?)", uids).collect{ |f| f.value_json['authorId'] }.uniq.size

  # Current number of newsletter subscribers
  data << TiplineSubscription.where(created_at: start_date.ago(100.years)..end_date, platform: platform_name).where('teams.slug' => slug).joins(:team).count.to_s

  # Number of imported reports
  data << ProjectMedia.joins(:team).where('teams.slug' => slug, 'created_at' => start_date..end_date, 'user_id' => BotUser.fetch_user.id).count.to_s

  puts data.join(',')
end

namespace :check do
  namespace :data do
    desc 'Generate some statistics about some workspaces'
    task statistics: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      args = params.to_a
      year = args[0].to_i
      start_month = args[1].to_i
      end_month = args[2].to_i
      group_by_month = args[3].to_i
      slugs = args[4].to_s.split('.')
      if slugs.empty?
        puts 'Please provide a list of workspace slugs'
      else
        header = ['Org', 'Platform', 'From', 'To']
        header << '# of conversations'
        header << '# of unique users'
        header << '# of valid queries (not in trash)'
        header << '# of new published reports (for all platforms)'
        header << '# of queries answered with a report'
        header << '# of users who received a report'
        header << '# of new newsletter subscriptions'
        header << '# of newsletter subscription cancellations'
        header << 'Average time to publishing (seconds)'
        header << 'Average time to publishing (readable)'
        header << 'Average number of end-user messages per day'
        header << '# of returning users (at least one session in the current month and at least one session in the last previous 2 months)'
        header << 'Current # of newsletter subscribers'
        header << 'Number of imported reports'
        puts header.join(',')

        slugs.each do |slug|
          team = Team.find_by_slug(slug)
          TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last.smooch_enabled_integrations.keys.each do |platform|
            if group_by_month == 1
              (start_month..end_month).to_a.each do |month|
                time = Time.parse("#{year}-#{month}-01")
                get_statistics(time.beginning_of_month, time.end_of_month, slug, platform)
              end
            else
              get_statistics(Time.parse("#{year}-#{start_month}-01"), Time.parse("#{year}-#{end_month}-01").end_of_month, slug, platform)
            end
          end
        end
      end
      ActiveRecord::Base.logger = old_logger
    end
  end
end
