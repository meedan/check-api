# bundle exec rake check:data:statistics[year,start_month,end_month,group_by_month (0 or 1),workspace_slugs_as_a_dot_separated_values_string]

require 'open-uri'

def get_statistics(start_date, end_date, slug)
  data = [Team.find_by_slug(slug).name, start_date, end_date]

  # Number of conversations
  value1 = Annotation.where(annotation_type: 'smooch').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).count.to_s
  value2 = Annotation.where(annotation_type: 'smooch').joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).count.to_s
  data << (value1 + value2) 
  
  # Number of unique users
  data << Annotation.where(annotation_type: 'smooch_user').joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND t.id = annotations.annotated_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).count.to_s

  # Number of valid queries
  data << Annotation.where(annotation_type: 'smooch').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).where('pm.archived' => 0).count.to_s

  # Number of new published reports
  data << Annotation.where(annotation_type: 'report_design').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('annotations.created_at' => start_date..end_date).count.to_s

  # Number of queries answered with a report
  data << DynamicAnnotation::Field.where(field_name: 'smooch_report_received').joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('dynamic_annotation_fields.created_at' => start_date..end_date).group('pm.id').count.size.to_s

  # Number of users who received a report
  data << DynamicAnnotation::Field.where(field_name: 'smooch_report_received').joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slug).where('dynamic_annotation_fields.created_at' => start_date..end_date).count.to_s

  # Number of new newsletter subscriptions
  data << TiplineSubscription.where(created_at: start_date..end_date).where('teams.slug' => slug).joins(:team).count.to_s

  # Number of newsletter subscription cancellations
  team = Team.find_by_slug(slug)
  data << Version.from_partition(team.id).where(created_at: start_date..end_date, team_id: team.id, item_type: 'TiplineSubscription', event_type: 'destroy_tiplinesubscription').count.to_s

  puts data.join(',')
end

namespace :check do
  namespace :data do
    desc 'Generate some statistics about some workspaces'
    task statistics: :environment do |_t, params|
      args = params.to_a
      year = args[0].to_i
      start_month = args[1].to_i
      end_month = args[2].to_i
      group_by_month = args[3].to_i
      slugs = args[4].to_s.split('.')
      if slugs.empty?
        puts 'Please provide a list of workspace slugs'
      else
        header = ['Org', 'From', 'To']
        header << '# of conversations'
        header << '# of new unique users'
        header << '# of valid queries (not in trash)'
        header << '# of new published reports'
        header << '# of queries answered with a report'
        header << '# of users who received a report'
        header << '# of new newsletter subscriptions'
        header << '# of newsletter subscription cancellations'
        puts header.join(',')

        slugs.each do |slug|
          if group_by_month == 1
            (start_month..end_month).to_a.each do |month|
              time = Time.parse("#{year}-#{month}-01")
              get_statistics(time.beginning_of_month, time.end_of_month, slug)
            end
          else
            get_statistics(Time.parse("#{year}-#{start_month}-01"), Time.parse("#{year}-#{end_month}-01").end_of_month, slug)
          end
        end
      end
    end
  end
end
