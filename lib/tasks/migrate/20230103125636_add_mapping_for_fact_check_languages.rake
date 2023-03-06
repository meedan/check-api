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

    task index_fact_check_languages: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_fact_check_languages:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 1000) do |pms|
          es_body = []
          ids = pms.map(&:id)
          ProjectMedia.select('project_medias.id as id, fc.language as language')
          .where(id: ids)
          .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
          .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
          .find_in_batches(:batch_size => 1000) do |items|
            print '.'
            items.each do |fc|
              doc_id = Base64.encode64("ProjectMedia/#{fc['id']}")
              fields = { 'fact_check_languages' => [fc['language']] }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_fact_check_languages:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task update_fact_check_reports_language: :environment do |_t, args|
      started = Time.now.to_i
      slug = args.extras.last
      team = Team.where(slug: slug).last
      raise "You must set a correct team slug." if team.nil?
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      data_csv = []
      team.project_medias
      .select('project_medias.id as id, project_medias.project_id as pid, fc.title as fc_title, fc.id as fc_id')
      .joins(:claim_description)
      .joins("INNER JOIN fact_checks fc ON fc.claim_description_id = claim_descriptions.id")
      .where('fc.language = ?', 'und').find_in_batches(:batch_size => 1000) do |items|
        fc_items = []
        fc_lang = {}
        es_body = []
        item_lang = {}
        items.each do |raw|
          print '.'
          lang = ::Bot::Alegre.get_language_from_alegre(raw.fc_title)
          fc_lang[raw.fc_id] = lang
          # Update reports
          item_lang[raw.id] = lang
          # Update ES
          doc_id = Base64.encode64("ProjectMedia/#{raw.id}")
          fields = { 'fact_check_languages' => [lang] }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          url = "#{CheckConfig.get('checkdesk_client')}/#{team.slug}/project/#{raw.pid}/media/#{raw.id}"
          data_csv << [raw.fc_title, lang, url]
        end
        # Update FactCheck: import items with existing ids to make update
        FactCheck.where(id: fc_lang.keys).find_each do |fc|
          fc.language = fc_lang[fc.id]
          fc_items << fc
        end
        FactCheck.import(fc_items, recursive: false, validate: false, on_duplicate_key_update: [:language])
        # Bulk update ES
        client.bulk body: es_body unless es_body.blank?
        # Update reports: import items with existing ids to make update
        report_items = []
        Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: item_lang.keys)
        .find_each do |report|
          data = report.data.with_indifferent_access
          unless data.blank?
            puts "[#{Time.now}] Updating report with ID #{report.id}..."
            # set report language
            data[:options][:language] = item_lang[report.annotated_id]
            report.data = data
            report_items << report
          end
        end
        Dynamic.import(report_items, recursive: false, validate: false, on_duplicate_key_update: [:data])
      end

      # Export reports with new languages to CSV
      require 'csv'
      file = "#{Rails.root}/public/#{team.slug}_reports_langauge_#{Time.now.to_i}.csv"
      headers = ["Title", "language", "URL"]
      CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
        data_csv.each do |d|
          writer << d
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "Exported reports with new language to file #{file}"
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task update_fact_check_reports_language_by_ids: :environment do |_t, args|
      started = Time.now.to_i
      data_args = parse_args args.extras
      # Add ProjectMedia condition
      pm_condition = {}
      unless data_args['ids'].blank?
        pm_ids = begin data_args['ids'].split('-').map{ |s| s.to_i } rescue [] end
        pm_condition = { id: pm_ids } unless pm_ids.blank?
      end
      lang = data_args['language']
      raise "You must set a correct language and ids." if pm_condition.blank? || lang.blank?
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      data_csv = []
      fc_items = []
      fc_lang = {}
      es_body = []
      item_lang = {}
      ProjectMedia.where(pm_condition)
      .select('project_medias.id as id, fc.title as fc_title, fc.id as fc_id')
      .joins(:claim_description)
      .joins("INNER JOIN fact_checks fc ON fc.claim_description_id = claim_descriptions.id")
      .find_each do |raw|
        print '.'
        fc_lang[raw.fc_id] = lang
        # Update reports
        item_lang[raw.id] = lang
        # Update ES
        doc_id = Base64.encode64("ProjectMedia/#{raw.id}")
        fields = { 'fact_check_languages' => [lang] }
        es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        url = "#{raw.id}"
        data_csv << [raw.fc_title, lang, url]
      end
      # Update FactCheck: import items with existing ids to make update
      FactCheck.where(id: fc_lang.keys).find_each do |fc|
        fc.language = fc_lang[fc.id]
        fc_items << fc
      end
      FactCheck.import(fc_items, recursive: false, validate: false, on_duplicate_key_update: [:language])
      # Bulk update ES
      client.bulk body: es_body unless es_body.blank?
      # Update reports: import items with existing ids to make update
      report_items = []
      Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: item_lang.keys)
      .find_each do |report|
        data = report.data.with_indifferent_access
        unless data.blank?
          puts "[#{Time.now}] Updating report with ID #{report.id}..."
          # set report language
          data[:options][:language] = item_lang[report.annotated_id]
          report.data = data
          report_items << report
        end
      end
      Dynamic.import(report_items, recursive: false, validate: false, on_duplicate_key_update: [:data])
      # Export reports with new languages to CSV
      require 'csv'
      file = "#{Rails.root}/public/ids_reports_langauge_#{Time.now.to_i}.csv"
      headers = ["Title", "language", "Item ID"]
      CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
        data_csv.each do |d|
          writer << d
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
