# bundle exec rake check:data:tipline_users[workspace-slug]

namespace :check do
  namespace :data do
    desc 'List tipline users'
    task tipline_users: :environment do |_t, params|
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

      team = Team.find_by_slug(params.to_a.first)
      raise "Workspace not found for slug '#{params.to_a}'" if team.nil?
      header = [
        'User ID',
        'WhatsApp #',
        'Number of conversations',
        'First seen',
        'Last seen',
        'Total requests submitted (included search)',
        'Requests with no search result, not in trash',
        'Requests with no search result, trashed',
        'Requests with no search result, marked as spam',
        'Request with no search result, answered with fact-checks',
        'Is subscribed to newsletter?'
      ]

      years = (team.created_at.year..Time.now.year).to_a
      threads = []
      years.each do |year|
        threads << Thread.new do
          o = File.open("tipline-users-#{team.slug}-#{year}-#{Time.now.strftime('%Y-%m-%d')}.csv", 'w+')
          date = Time.parse("#{year}-01-01")
          query = Dynamic.where(annotation_type: 'smooch_user', annotated_type: 'Team', annotated_id: team.id, created_at: date.beginning_of_year..date.end_of_year)
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
            row << uid
            row << data.dig('raw', 'clients', 0, 'displayName').to_s.gsub(/^[^:]+:/, '')
            row << number_of_user_requests(uid)
            row << user_requests(uid).first&.created_at
            row << user_requests(uid).last&.created_at
            row << user_requests(uid).where('annotations.annotated_type' => 'ProjectMedia').count
            row << number_of_user_requests(uid, 'default_requests', CheckArchivedFlags::FlagCodes::NONE)
            row << number_of_user_requests(uid, 'default_requests', CheckArchivedFlags::FlagCodes::TRASHED)
            row << number_of_user_requests(uid, 'default_requests', CheckArchivedFlags::FlagCodes::SPAM)
            row << number_of_user_requests(uid, 'default_requests', nil, true)
            row << (TiplineSubscription.where(uid: uid).count > 0 ? 'Yes' : 'No')
            puts row.join(',')
            o.puts(row.join(','))
          end
          o.close
        end
      end
      threads.map(&:join)
      ActiveRecord::Base.logger = old_logger
    end
  end
end
