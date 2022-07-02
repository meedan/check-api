# bundle exec rake check:data:report[year,slugs (separated by dots)]

namespace :check do
  namespace :data do
    desc 'Generate data for the annual report. Usage: rake check:data:report[year,slugs]'
    task report: :environment do |_t, params|
      def get_statistics(start_date, end_date, slugs)
        data = []
      
        relationship_join = 'INNER JOIN project_medias pm ON pm.id = relationships.target_id INNER JOIN teams t ON t.id = pm.team_id'
        field_join = "INNER JOIN annotations a ON dynamic_annotation_fields.annotation_id = a.id INNER JOIN project_medias pm ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = pm.id INNER JOIN teams t ON t.id = pm.team_id"
      
        # Claims matched automatically (for all platforms and languages)
        claims_auto = Relationship.joins(relationship_join).where('t.slug' => slugs).where(created_at: start_date..end_date).confirmed.where('relationships.user_id' => BotUser.alegre_user.id).count
        data << claims_auto
      
        # Claims matched manually
        claims_manual = Relationship.joins(relationship_join).where('t.slug' => slugs).where(created_at: start_date..end_date).confirmed.where.not('relationships.user_id' => BotUser.alegre_user.id).count
        data << claims_manual
      
        # Claims matched
        data << (claims_auto + claims_manual)
      
        # Unique end users
        data << Annotation.joins("INNER JOIN teams t ON annotations.annotated_type = 'Team' AND annotations.annotated_id = t.id").where('t.slug' => slugs).where(annotation_type: 'smooch_user', created_at: start_date..end_date).count
      
        # Unique claims
        data << Relationship.joins(relationship_join).where('t.slug' => slugs).where(created_at: start_date..end_date).confirmed.group(:source_id).count.size
      
        # Reports sent to users
        data << DynamicAnnotation::Field.joins(field_join).where('t.slug' => slugs).where(field_name: 'smooch_report_received', created_at: start_date..end_date).count
      
        # Bot resources sent
        data << DynamicAnnotation::Field.joins(field_join).where('t.slug' => slugs).where(field_name: 'smooch_request_type', created_at: start_date..end_date, value: 'resource_requests').count
      
        # Reports published
        data << Annotation.joins("INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia' AND annotations.annotated_id = pm.id INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slugs).where(annotation_type: 'report_design', created_at: start_date..end_date).where("data LIKE '%state: published%'").count
      
        # Number of tiplines
        data << TeamBotInstallation.where(user_id: BotUser.smooch_user.id).where('team_users.created_at < ?', end_date).joins(:team).where('teams.slug' => slugs).count
      
        puts data.join(',')
      end

      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      year = params.to_a.first.to_i
      time = Time.parse("#{year}-01-01")
      slugs = params.to_a[1] ? params.to_a[1].split('.') : Team.where('created_at < ?', time.end_of_year).map(&:slug)
      header = [
        'Claims matched automatically',
        'Claims matched manually',
        'Claims matched',
        'Unique end users',
        'Unique claims',
        'Reports sent to users',
        'Bot resources sent',
        'Reports published',
        'Number of tiplines'
      ]
      puts header.join(',')
      get_statistics(time.beginning_of_year, time.end_of_year, slugs)
      ActiveRecord::Base.logger = old_logger
    end
  end
end
