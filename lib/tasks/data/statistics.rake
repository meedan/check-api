# bundle exec rake check:data:statistics[year,start_month,end_month,group_by_month (0 or 1),workspace_slugs_as_a_dot_separated_values_string]

require 'open-uri'

def get_statistics(start_date, end_date, slugs)
  data = [start_date, end_date]
  relationships_query = Relationship.joins('INNER JOIN project_medias pm ON pm.id = relationships.source_id INNER JOIN teams t ON t.id = pm.team_id').where('t.slug' => slugs).where('relationships.created_at' => start_date..end_date)
  
  { 'video' => 'UploadedVideo', 'audio' => 'UploadedAudio', 'image' => 'UploadedImage', 'text' => ['Claim', 'Link'] }.each do |type, klass|
    ['confirmed', 'suggested'].each do |relationship_type|
      data << relationships_query.joins('INNER JOIN medias m ON m.id = pm.media_id').where('m.type' => klass).send(relationship_type).count.to_s
    end
  end
  
  data << Annotation.where(annotation_type: 'extracted_text').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia' INNER JOIN teams t ON t.id = pm.team_id").where('t.slug' => slugs).where('annotations.created_at' => start_date..end_date).count.to_s
  data << ProjectMedia.joins(:team).where('teams.slug' => slugs).where('project_medias.created_at' => start_date..end_date).count.to_s
  data << TiplineSubscription.where(created_at: start_date..end_date).where('teams.slug' => slugs).group(:team_id).joins(:team).count.collect{ |id, count| "#{Team.find(id).name} (#{count})" }.join(',')
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
        # puts "Getting data from #{start_month}/#{year} to #{end_month}/#{year} for workspaces #{slugs.join(', ')}#{group_by_month == 1 ? ' (grouped by month)' : ''}."
        header = ['From', 'To']
        { 'video' => 'UploadedVideo', 'audio' => 'UploadedAudio', 'image' => 'UploadedImage', 'text' => ['Claim', 'Link'] }.each do |type, klass|
          ['confirmed', 'suggested'].each do |relationship_type|
            header << "Number of #{type} #{relationship_type}"
          end
        end
        header << 'Number of OCR’d images'
        header << 'Number of claims available through the search DB'
        header << 'Number of users who opted-in / received the newsletter, per publisher'
        puts header.join(',')

        if group_by_month == 1
          (start_month..end_month).to_a.each do |month|
            get_statistics(Time.parse("#{year}-#{month}-01"), Time.parse("#{year}-#{month+1}-01"), slugs)
          end
        else
          get_statistics(Time.parse("#{year}-#{start_month}-01"), Time.parse("#{year}-#{end_month}-01"), slugs)
        end
      end
    end
  end
end
