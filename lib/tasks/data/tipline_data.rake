# bundle exec rake check:data:tipline_data[workspace-slug]

namespace :check do
  namespace :data do
    desc 'Export tipline data'
    task tipline_data: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      def user_requests(uid, type = nil, archived = nil, answered = nil)
        relation = Annotation
          .where(annotation_type: 'smooch')
          .joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_data'")
          .where("fs.value_json->>'authorId' = ?", uid)
        unless type.nil?
          request_type_join = "INNER JOIN dynamic_annotation_fields fs2 ON fs2.annotation_id = annotations.id AND fs2.field_name = 'smooch_request_type'"
          relation = relation.joins(request_type_join).where('fs2.value' => type.to_json)
        end
        unless archived.nil?
          archived_join = "INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'"
          relation = relation.joins(archived_join).where('pm.archived' => archived)
        end
        unless answered.nil?
          answered_join = "INNER JOIN dynamic_annotation_fields fs3 ON fs3.annotation_id = annotations.id AND fs3.field_name = 'smooch_report_received'"
          relation = relation.joins(answered_join)
        end
        relation
      end

      def number_of_user_requests(uid, type = nil, archived = nil, answered = nil)
        user_requests(uid, type, archived, answered).count
      end

      def output_row(file, row)
        row = row.collect{ |x| '"' + x.to_s.gsub('"', "'") + '"' }.join(',')
        file.puts row
      end

      team = Team.find_by_slug(params.to_a.first)
      raise "Workspace not found for slug '#{params.to_a}'" if team.nil?
      header = [
        'Channel',
        'User ID',
        'User name',
        'Phone number or display name',
        'Number of requests',
        'Date last subscribed to newsletter',
        'Date last unsubscribed to newsletter',
        'Date banned',
        'Requests'
      ]

      puts "[#{Time.now}] Exporting tipline users data..."
      o = File.open(File.join(Rails.root, 'tmp', "tipline-data-#{team.slug}-#{Time.now.strftime('%Y-%m-%d')}.csv"), 'w+')
      output_row(o, header)
      query = Dynamic.where(annotation_type: 'smooch_user', annotated_type: 'Team', annotated_id: team.id)
      i = 0
      n = query.count
      query.find_each do |user|
        i += 1
        puts "[#{Time.now}] #{i}/#{n}"
        data = begin
          JSON.parse(user.get_field_value('smooch_user_data'))
        rescue
          next
        end
        uid = data['id']
        row = []
        row << data.dig('raw', 'clients', 0, 'platform')
        row << uid
        row << Bot::Smooch.get_user_name_from_uid(uid)
        row << data.dig('raw', 'clients', 0, 'displayName').to_s.gsub(/^[^:]+:/, '')
        row << number_of_user_requests(uid)
        row << TiplineSubscription.where(uid: uid).last&.created_at || Version.from_partition(team.id).where(item_type: 'TiplineSubscription', event: 'create').where('object_after LIKE ?', "%#{uid}%").last&.created_at
        row << Version.from_partition(team.id).where(item_type: 'TiplineSubscription', event: 'destroy').where('object LIKE ?', "%#{uid}%").last&.created_at
        row << begin JSON.parse(Rails.cache.read("smooch:banned:#{uid}"))['received'] rescue nil end 
        first = true
        user_requests(uid).find_each do |request|
          content = begin JSON.parse(request.load.get_field_value('smooch_data'))['text'] rescue '' end
          if first
            first = false
          else
            row = ['', '', '', '', '', '', '', '']
          end
          row << content
          output_row(o, row)
        end
        output_row(o, row) if first
      end
      o.close

      header = [
        'ID',
        'Published',
        'Unpublished',
        'Claim',
        'Context',
        'Title',
        'URL',
        'Summary',
        'Media content',
        'Media ID'
      ]

      puts "[#{Time.now}] Exporting fact-checks..."
      o = File.open(File.join(Rails.root, 'tmp', "tipline-content-#{team.slug}-#{Time.now.strftime('%Y-%m-%d')}.csv"), 'w+')
      output_row(o, header)
      query = Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia').joins('INNER JOIN project_medias pm ON pm.id = annotations.annotated_id').where('pm.team_id' => team.id)
      i = 0
      n = query.count
      query.find_each do |report|
        i += 1
        puts "[#{Time.now}] #{i}/#{n}"
        data = report.data.to_h.with_indifferent_access
        row = []
        row << report.id
        row << (data['last_published'].blank? ? '' : Time.at(data['last_published'].to_i))
        row << (data['state'] != 'published' ? report.updated_at : '')
        pm = report.annotated
        row << pm.claim_description_content
        row << pm.claim_description_context
        row << pm.fact_check_title
        row << pm.fact_check_url
        row << pm.fact_check_summary
        row << (pm.media.url || pm.media.quote || pm.media.file&.file&.public_url || pm.original_title || '')
        row << pm.id
        output_row(o, row)
        Relationship.where(relationship_type: Relationship.confirmed_type, source_id: pm.id).find_each do |relationship|
          pm2 = relationship.target
          next if pm2.nil?
          media = pm2.media
          media_content = (media.url || media.quote || media.file&.file&.public_url || '')
          row = ['', '', '', '', '', '', '', '', media_content, pm2.id]
          output_row(o, row)
        end
      end
      o.close
      puts "[#{Time.now}] Done. Output is in tmp/."

      ActiveRecord::Base.logger = old_logger
    end
  end
end
