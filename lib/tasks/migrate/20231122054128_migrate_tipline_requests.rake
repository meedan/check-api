namespace :check do
  namespace :migrate do
    def parse_args(args)
      output = {}
      return output if args.blank?
      args.each do |a|
        arg = a.split('&')
        arg.each do |pair|
          key, value = pair.split(':')
          output.merge!({ key => value })
        end
      end
      output
    end
    # Migrate TiplineRequests
    # bundle exec rake check:migrate:migrate_tipline_requests
    task migrate_tipline_requests: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:migrate_tipline_requests:team_id') || 0
      failed_teams = []
      Team.where('id > ?', last_team_id).find_each do |team|
        # Get the total count for team requests
        total_count = team.project_medias.joins("INNER JOIN annotations a ON a.annotated_id = project_medias.id")
        .where("a.annotated_type = ? AND a.annotation_type = ?", 'ProjectMedia', 'smooch').count
        puts "Migrating team #{team.slug} with #{total_count} requests"
        inserts = 0
        team.project_medias.find_in_batches(:batch_size => 50) do |pms|
          print '.'
          smooch_pm = {}
          smooch_user = {}
          pm_requests = Hash.new {|hash, key| hash[key] = [] }
          pm_ids = pms.map(&:id)
          # Collect request associated id and user id
          Annotation.where(annotation_type: 'smooch', annotated_type: 'ProjectMedia', annotated_id: pm_ids).find_each do |d|
            print '.'
            smooch_pm[d.id] = d.annotated_id
            smooch_user[d.id] = d.annotator_id
          end
          DynamicAnnotation::Field.where(annotation_type: 'smooch', annotation_id: smooch_pm.keys).find_each do |f|
            print '.'
            value = f.value
            # I mapped `smooch_report_received` field in two columns `smooch_report_received_at` & `smooch_report_update_received_at`
            field_name = f.field_name == 'smooch_report_received' ? 'smooch_report_received_at' : f.field_name
            if field_name == 'smooch_data'
              value.gsub!('\u0000', '') if value.is_a?(String) # Avoid PG::UntranslatableCharacter exception
              value = begin JSON.parse(value) rescue {} end
              # These fields are indifferent TiplineRequest columns so collect these fields with their values
              # N.B: I set smooch_data.id as a primary key for TiplineRequest table
              # and set a default values for some columns to avoid PG error
              sd_fields = [
                { 'id' => f.id },
                { 'tipline_user_uid' => value.dig('authorId') },
                { 'language' => value.dig('language') || 'en' },
                { 'platform' => value.dig('source', 'type') || 'whatsapp' },
                { 'created_at' => f.created_at },
                { 'updated_at' => f.updated_at },
              ]
              pm_requests[f.annotation_id].concat(sd_fields)
            end
            pm_requests[f.annotation_id] << { field_name => value }
            if field_name == 'smooch_report_received_at' && f.created_at != f.updated_at
              # Get the value for `smooch_report_update_received_at` column
              pm_requests[f.annotation_id] << { 'smooch_report_update_received_at' => value }
            end
          end
          requests = []
          pm_requests.each do |d_id, fields|
            # Build TiplineRequest raw and should include all existing columns
            r = {
              associated_type: 'ProjectMedia',
              associated_id: smooch_pm[d_id],
              user_id: smooch_user[d_id],
              team_id: team.id,
              smooch_request_type: 'default_requests',
              smooch_resource_id: nil,
              smooch_message_id: '',
              smooch_conversation_id: nil,
              smooch_report_received_at: 0,
              smooch_report_update_received_at: 0,
              smooch_report_correction_sent_at: 0,
              smooch_report_sent_at: 0,
            }.with_indifferent_access
            fields.each do |raws|
              raws.each{|k, v| r[k] = v }
            end
            requests << r
          end
          unless requests.blank?
            inserts += requests.count
            puts "\n#{team.slug}:: Importing #{inserts}/#{total_count} requests\n"
            begin
              TiplineRequest.insert_all(requests) unless requests.blank?
            rescue
              failed_teams << team.id unless failed_teams.include?(team.id)
            end
          end
        end
        Rails.cache.write('check:migrate:migrate_tipline_requests:team_id', team.id)
      end
      puts "Failed to import some requests related to the following teams #{failed_teams.inspect}" if failed_teams.length > 0
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # list teams that have a different count between TiplineRequest and smooch annotation (list teams that not fully migrated)
    # bundle exec rake check:migrate:migrate_tipline_requests_status[team_slug1, team_slug2, ...]
    task migrate_tipline_requests_status: :environment do |_t, args|
      # Get missing requests based on a comparison between TiplineRequest.id and smooch_data field id
      slugs = args.extras
      condition = {}
      condition = { slug: slugs } unless slugs.blank?
      logs = []
      Team.where(condition).find_each do |team|
        print '.'
        requests_ids = TiplineRequest.where(team_id: team.id).map(&:id)
        requests_count = requests_ids.count
        smooch_ids = Annotation.where(annotation_type: 'smooch', annotated_type: 'ProjectMedia')
        .joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id")
        .where('pm.team_id = ?', team.id)
        sd_ids = DynamicAnnotation::Field.where(field_name: 'smooch_data', annotation_type: 'smooch', annotation_id: smooch_ids)
        .where.not(id: requests_ids).map(&:id)
        logs << {id: team.id, slug: team.slug, requests: requests_count, smooch: sd_ids} if sd_ids.length > 0
      end
      puts "List of teams that not fully migrated"
      pp logs
    end

    # Migrate missing requests related to specific teams
    # bundle exec rake check:migrate:migrate_tipline_requests_missing_requests['slug:team_slug&batch_size:batch_size']
    task migrate_tipline_requests_missing_requests: :environment do |_t, args|
      data_args = parse_args args.extras
      slug = data_args['slug']
      raise "You must call rake task with team slugs" if slug.blank?
      condition = { slug: slug }
      batch_size = data_args['batch_size'] || 1000
      started = Time.now.to_i
      Team.where(condition).find_each do |team|
        print '.'
        requests_ids = TiplineRequest.where(team_id: team.id).map(&:id)
        smooch_ids = Annotation.where(annotation_type: 'smooch', annotated_type: 'ProjectMedia')
        .joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id")
        .where('pm.team_id = ?', team.id).map(&:id)
        sd_fields = DynamicAnnotation::Field.where(field_name: 'smooch_data', annotation_type: 'smooch', annotation_id: smooch_ids)
        .where.not(id: requests_ids)
        sd_ids = sd_fields.map(&:id)
        if sd_ids.length > 0
          total_count = sd_ids.length
          inserts = 0
          print '.'
          smooch_ids = sd_fields.map(&:annotation_id)
          Annotation.where(id: smooch_ids).find_in_batches(:batch_size => batch_size) do |annotations|
            smooch_pm = {}
            smooch_user = {}
            pm_requests = Hash.new {|hash, key| hash[key] = [] }
            annotations.each do |d|
              print '.'
              smooch_pm[d.id] = d.annotated_id
              smooch_user[d.id] = d.annotator_id
            end
            DynamicAnnotation::Field.where(annotation_type: 'smooch', annotation_id: annotations.map(&:id)).find_each do |f|
              print '.'
              value = f.value
              field_name = f.field_name == 'smooch_report_received' ? 'smooch_report_received_at' : f.field_name
              if field_name == 'smooch_data'
                value.gsub!('\u0000', '') if value.is_a?(String) # Avoid PG::UntranslatableCharacter exception
                value = begin JSON.parse(value) rescue {} end
                sd_fields = [
                  { 'id' => f.id },
                  { 'tipline_user_uid' => value.dig('authorId') },
                  { 'language' => value.dig('language') || 'en' },
                  { 'platform' => value.dig('source', 'type') || 'whatsapp' },
                  { 'created_at' => f.created_at },
                  { 'updated_at' => f.updated_at },
                ]
                pm_requests[f.annotation_id].concat(sd_fields)
              end
              pm_requests[f.annotation_id] << { field_name => value }
              if field_name == 'smooch_report_received_at' && f.created_at != f.updated_at
                pm_requests[f.annotation_id] << { 'smooch_report_update_received_at' => value }
              end
            end
            requests = []
            pm_requests.each do |d_id, fields|
              r = {
                associated_type: 'ProjectMedia',
                associated_id: smooch_pm[d_id],
                user_id: smooch_user[d_id],
                team_id: team.id,
                smooch_request_type: 'default_requests',
                smooch_resource_id: nil,
                smooch_message_id: '',
                smooch_conversation_id: nil,
                smooch_report_received_at: 0,
                smooch_report_update_received_at: 0,
                smooch_report_correction_sent_at: 0,
                smooch_report_sent_at: 0,
              }.with_indifferent_access
              fields.each do |raws|
                raws.each{|k, v| r[k] = v }
              end
              requests << r
            end
            unless requests.blank?
              inserts += requests.count
              puts "\n#{team.slug}:: Importing #{inserts}/#{total_count} requests\n"
              TiplineRequest.insert_all(requests) unless requests.blank?
            end
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
