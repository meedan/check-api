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

    def migrate_team_tipline_requests(team, batch_size)
      total_count = Annotation.where(annotation_type:  'smooch', annotated_type: 'Team', annotated_id: team.id).count
      failed_teams = []
      if total_count > 0
        puts "\nMigrating Team requests[#{team.slug}]: #{total_count} requests"
        inserts = 0
        Annotation.where(annotation_type: 'smooch', annotated_type: 'Team', annotated_id: team.id)
        .find_in_batches(:batch_size => batch_size) do |annotations|
          print '.'
          smooch_obj = {}
          smooch_user = {}
          obj_requests = Hash.new {|hash, key| hash[key] = [] }
          # Collect request associated id and user id
          annotations.each do |d|
            smooch_obj[d.id] = d.annotated_id
            smooch_user[d.id] = d.annotator_id
          end
          DynamicAnnotation::Field.where(annotation_type: 'smooch', annotation_id: smooch_obj.keys).find_each do |f|
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
              obj_requests[f.annotation_id].concat(sd_fields)
            end
            obj_requests[f.annotation_id] << { field_name => value }
            if field_name == 'smooch_report_received_at' && f.created_at != f.updated_at
              # Get the value for `smooch_report_update_received_at` column
              obj_requests[f.annotation_id] << { 'smooch_report_update_received_at' => value }
            end
          end
          requests = []
          obj_requests.each do |d_id, fields|
            # Build TiplineRequest raw and should include all existing columns
            r = {
              associated_type: 'Team',
              associated_id: smooch_obj[d_id],
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
            puts "\nImporting Team requests[#{team.slug}]: #{inserts}/#{total_count}\n"
            begin
              TiplineRequest.insert_all(requests)
            rescue
              failed_teams << team.id unless failed_teams.include?(team.id)
            end
          end
        end
      end
      failed_teams
    end

    def migrate_missing_team_tipline_requests(team, batch_size)
      failed_teams = []
      puts "\nMigrating missing Team requests[#{team.slug}]"
      inserts = 0
      smooch_data_ids = DynamicAnnotation::Field.where(field_name: 'smooch_data')
      .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
      .where('a.annotated_type' => 'Team', 'a.annotated_id' => team.id).map(&:id)
      existing_smooch_data_ids = TiplineRequest.where(id: smooch_data_ids, team_id: team.id).map(&:id)
      diff = smooch_data_ids - existing_smooch_data_ids
      if diff.length > 0
        Annotation.where(annotation_type: 'smooch', annotated_type: 'Team', annotated_id: team.id)
        .joins("INNER JOIN  dynamic_annotation_fields f ON f.annotation_id = annotations.id AND f.field_name = 'smooch_data'")
        .where('f.id IN (?)', diff)
        .find_in_batches(:batch_size => batch_size) do |annotations|
          print '.'
          smooch_obj = {}
          smooch_user = {}
          obj_requests = Hash.new {|hash, key| hash[key] = [] }
          # Collect request associated id and user id
          annotations.each do |d|
            smooch_obj[d.id] = d.annotated_id
            smooch_user[d.id] = d.annotator_id
          end
          DynamicAnnotation::Field.where(annotation_type: 'smooch', annotation_id: smooch_obj.keys).find_each do |f|
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
              obj_requests[f.annotation_id].concat(sd_fields)
            end
            obj_requests[f.annotation_id] << { field_name => value }
            if field_name == 'smooch_report_received_at' && f.created_at != f.updated_at
              # Get the value for `smooch_report_update_received_at` column
              obj_requests[f.annotation_id] << { 'smooch_report_update_received_at' => value }
            end
          end
          requests = []
          obj_requests.each do |d_id, fields|
            # Build TiplineRequest raw and should include all existing columns
            r = {
              associated_type: 'Team',
              associated_id: smooch_obj[d_id],
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
            puts "\nImporting Team requests[#{team.slug}]: #{inserts}\n"
            begin
              TiplineRequest.insert_all(requests)
            rescue
              failed_teams << team.id unless failed_teams.include?(team.id)
            end
          end
        end
      end
      failed_teams
    end

    def bulk_import_requests_items(annotated_type, ids, team_id)
      print '.'
      smooch_obj = {}
      smooch_user = {}
      obj_requests = Hash.new {|hash, key| hash[key] = [] }
      # Collect request associated id and user id
      Annotation.where(annotation_type: 'smooch', annotated_type: annotated_type, annotated_id: ids).find_each do |d|
        print '.'
        smooch_obj[d.id] = d.annotated_id
        smooch_user[d.id] = d.annotator_id
      end
      DynamicAnnotation::Field.where(annotation_type: 'smooch', annotation_id: smooch_obj.keys).find_each do |f|
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
          obj_requests[f.annotation_id].concat(sd_fields)
        end
        obj_requests[f.annotation_id] << { field_name => value }
        if field_name == 'smooch_report_received_at' && f.created_at != f.updated_at
          # Get the value for `smooch_report_update_received_at` column
          obj_requests[f.annotation_id] << { 'smooch_report_update_received_at' => value }
        end
      end
      requests = []
      obj_requests.each do |d_id, fields|
        # Build TiplineRequest raw and should include all existing columns
        r = {
          associated_type: annotated_type,
          associated_id: smooch_obj[d_id],
          user_id: smooch_user[d_id],
          team_id: team_id,
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
      requests
    end
    # Migrate TiplineRequests
    # bundle exec rails check:migrate:migrate_tipline_requests['slug:team_slug&batch_size:batch_size']
    task migrate_tipline_requests: :environment do |_t, args|
      started = Time.now.to_i
      data_args = parse_args args.extras
      batch_size = data_args['batch_size'] || 1500
      batch_size = batch_size.to_i
      slug = data_args['slug']
      condition = {}
      last_team_id = Rails.cache.read('check:migrate:migrate_tipline_requests:team_id') || 0
      unless slug.blank?
        last_team_id = 0
        if slug == 'custom_slugs'
          puts "Type team slugs separated by comma then press enter"
          print ">> "
          slug = begin STDIN.gets.chomp.split(',').map{ |s| s.to_s } rescue [] end
          raise "You must call rake task with team slugs" if slug.blank?
        end
        condition = { slug: slug }
      end
      failed_project_media_requests = []
      failed_team_requests = []
      failed_tipline_resource_requests = []
      Team.where(condition).where('id > ?', last_team_id).find_each do |team|
        print '.'
        migrate_teams = Rails.cache.read('check:migrate:migrate_tipline_requests:migrate_teams') || []
        next if migrate_teams.include?(team.id)
        # Migrated Team requests
        failed_team_requests = migrate_team_tipline_requests(team, batch_size)
        # Migrate TiplineResource requests
        total_count = team.tipline_resources.joins("INNER JOIN annotations a ON a.annotated_id = tipline_resources.id")
        .where("a.annotated_type = ? AND a.annotation_type = ?", 'TiplineResource', 'smooch').count
        if total_count > 0
          puts "\nMigrating TiplineResource requests[#{team.slug}]: #{total_count} requests"
          inserts = 0
          team.tipline_resources.find_in_batches(:batch_size => batch_size) do |items|
            print '.'
            ids = items.map(&:id)
            requests = bulk_import_requests_items('TiplineResource', ids, team.id)
            unless requests.blank?
              inserts += requests.count
              puts "\nImporting TiplineResource[#{team.slug}]: #{inserts}/#{total_count}\n"
              begin
                TiplineRequest.insert_all(requests)
              rescue
                failed_tipline_resource_requests << team.id unless failed_tipline_resource_requests.include?(team.id)
              end
            end
          end
        end
        # Migrate ProjectMedia requests
        # Get the total count for team requests
        total_count = team.project_medias.joins("INNER JOIN annotations a ON a.annotated_id = project_medias.id")
        .where("a.annotated_type = ? AND a.annotation_type = ?", 'ProjectMedia', 'smooch').count
        if total_count > 0
          puts "\nMigrating ProjectMedia requests[#{team.slug}]: #{total_count} requests"
          inserts = 0
          team.project_medias.find_in_batches(:batch_size => batch_size) do |pms|
            print '.'
            ids = pms.map(&:id)
            requests = bulk_import_requests_items('ProjectMedia', ids, team.id)
            unless requests.blank?
              inserts += requests.count
              puts "\nImporting ProjectMedia requests[#{team.slug}]: #{inserts}/#{total_count}\n"
              begin
                TiplineRequest.insert_all(requests)
              rescue
                failed_teams << team.id unless failed_teams.include?(team.id)
              end
            end
          end
        end
        unless slug.blank?
          migrate_teams << team.id
          Rails.cache.write('check:migrate:migrate_tipline_requests:migrate_teams', migrate_teams)
        end
        Rails.cache.write('check:migrate:migrate_tipline_requests:team_id', team.id) if slug.blank?
      end
      puts "Failed to import some project media requests related to the following teams #{failed_project_media_requests.inspect}" if failed_project_media_requests.length > 0
      puts "Failed to import some team requests related to the following teams #{failed_team_requests.inspect}" if failed_team_requests.length > 0
      puts "Failed to import some tipline resource requests related to the following teams #{failed_tipline_resource_requests.inspect}" if failed_tipline_resource_requests.length > 0
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # list teams that have a different count between TiplineRequest and smooch annotation (list teams that not fully migrated)
    # bundle exec rails check:migrate:migrate_tipline_requests_status[team_slug1, team_slug2, ...]
    task migrate_tipline_requests_status: :environment do |_t, args|
      # Get missing requests based on a comparison between TiplineRequest.id and smooch_data field id
      slugs = args.extras
      condition = {}
      condition = { slug: slugs } unless slugs.blank?
      logs = []
      Team.where(condition).find_each do |team|
        print '.'
        diff = {}
        # Team tequests
        tr_team_c = TiplineRequest.where(associated_type: 'Team', team_id: team.id).count
        smooch_team_c = Annotation.where(annotation_type:  'smooch', annotated_type: 'Team', annotated_id: team.id).count
        diff[:team] = { existing: smooch_team_c, migrated: tr_team_c } if smooch_team_c > tr_team_c
        # TiplineResource requests
        tr_resource_c = TiplineRequest.where(associated_type: 'TiplineResource', team_id: team.id).count
        smooch_resource_c = team.tipline_resources.joins("INNER JOIN annotations a ON a.annotated_id = tipline_resources.id")
        .where("a.annotated_type = ? AND a.annotation_type = ?", 'TiplineResource', 'smooch').count
        diff[:tipline_resource] = { existing: smooch_resource_c, migrated: tr_resource_c } if smooch_resource_c > tr_resource_c
        # ProjectMedia request
        tr_pm_c = TiplineRequest.where(associated_type: 'ProjectMedia', team_id: team.id).count
        smooch_tr_c = team.project_medias.joins("INNER JOIN annotations a ON a.annotated_id = project_medias.id")
        .where("a.annotated_type = ? AND a.annotation_type = ?", 'ProjectMedia', 'smooch').count
        diff[:project_media] = { existing: smooch_tr_c, migrated: tr_pm_c } if smooch_tr_c > tr_pm_c
        # Add to logs
        unless diff.blank?
          diff[:team_slug] = team.slug
          logs << diff
        end
      end
      puts "List of teams that not fully migrated"
      pp logs
    end

    # Migrate missing requests related to specific teams
    # bundle exec rails check:migrate:migrate_tipline_requests_missing_requests['slug:team_slug&batch_size:batch_size']
    task migrate_tipline_requests_missing_requests: :environment do |_t, args|
      started = Time.now.to_i
      data_args = parse_args args.extras
      batch_size = data_args['batch_size'] || 1500
      batch_size = batch_size.to_i
      slug = data_args['slug']
      condition = {}
      last_team_id = Rails.cache.read('check:migrate:migrate_tipline_requests_missing_requests:team_id') || 0
      unless slug.blank?
        last_team_id = 0
        if slug == 'custom_slugs'
          puts "Type team slugs separated by comma then press enter"
          print ">> "
          slug = begin STDIN.gets.chomp.split(',').map{ |s| s.to_s } rescue [] end
          raise "You must call rake task with team slugs" if slug.blank?
        end
        condition = { slug: slug }
      end
      failed_project_media_requests = []
      failed_team_requests = []
      failed_tipline_resource_requests = []
      Team.where(condition).where('id > ?', last_team_id).find_each do |team|
        print '.'
        # Migrated missing Team requests
        failed_team_requests = migrate_missing_team_tipline_requests(team, batch_size)
        # Migrate missing TiplineResource requests
        puts "\nMigrating missing TiplineResource requests[#{team.slug}]"
        inserts = 0
        team.tipline_resources.find_in_batches(:batch_size => batch_size) do |items|
          print '.'
          smooch_data_ids = DynamicAnnotation::Field.where(field_name: 'smooch_data')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
          .where('a.annotated_type' => 'TiplineResource', 'a.annotated_id' => items.map(&:id)).map(&:id)
          existing_smooch_data_ids = TiplineRequest.where(id: smooch_data_ids, team_id: team.id).map(&:id)
          diff = smooch_data_ids - existing_smooch_data_ids
          if diff.length > 0
            ids = Annotation.where(annotation_type: 'smooch', annotated_type: 'TiplineResource')
            .joins("INNER JOIN  dynamic_annotation_fields f ON f.annotation_id = annotations.id AND f.field_name = 'smooch_data'")
            .where('f.id IN (?)', diff).map(&:annotated_id)
            requests = bulk_import_requests_items('TiplineResource', ids, team.id)
            unless requests.blank?
              inserts += requests.count
              puts "\nImporting missing TiplineResource[#{team.slug}]: #{inserts}\n"
              begin
                TiplineRequest.insert_all(requests)
              rescue
                failed_tipline_resource_requests << team.id unless failed_tipline_resource_requests.include?(team.id)
              end
            end
          end
        end
        # Migrate missing ProjectMedia requests
        puts "\nMigrating missing ProjectMedia requests[#{team.slug}]"
        inserts = 0
        team.project_medias.find_in_batches(:batch_size => batch_size) do |pms|
          print '.'
          smooch_data_ids = DynamicAnnotation::Field.where(field_name: 'smooch_data')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
          .where('a.annotated_type' => 'ProjectMedia', 'a.annotated_id' => pms.map(&:id)).map(&:id)
          existing_smooch_data_ids = TiplineRequest.where(id: smooch_data_ids, team_id: team.id).map(&:id)
          diff = smooch_data_ids - existing_smooch_data_ids
          if diff.length > 0
            ids = Annotation.where(annotation_type: 'smooch', annotated_type: 'ProjectMedia')
            .joins("INNER JOIN  dynamic_annotation_fields f ON f.annotation_id = annotations.id AND f.field_name = 'smooch_data'")
            .where('f.id IN (?)', diff).map(&:annotated_id)
            requests = bulk_import_requests_items('ProjectMedia', ids, team.id)
            unless requests.blank?
              inserts += requests.count
              puts "\nImporting missing ProjectMedia requests[#{team.slug}]: #{inserts}\n"
              begin
                TiplineRequest.insert_all(requests)
              rescue
                failed_teams << team.id unless failed_teams.include?(team.id)
              end
            end
          end
        end
        Rails.cache.write('check:migrate:migrate_tipline_requests_missing_requests:team_id', team.id) if slug.blank?
      end
      puts "Failed to import some project media requests related to the following teams #{failed_project_media_requests.inspect}" if failed_project_media_requests.length > 0
      puts "Failed to import some team requests related to the following teams #{failed_team_requests.inspect}" if failed_team_requests.length > 0
      puts "Failed to import some tipline resource requests related to the following teams #{failed_tipline_resource_requests.inspect}" if failed_tipline_resource_requests.length > 0
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
