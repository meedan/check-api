namespace :check do
  namespace :migrate do
    task add_language_to_fact_check: :environment do
      started = Time.now.to_i
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:add_language_to_fact_check:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        language = team.default_language || 'en'
        team.project_medias.select('fc.*')
        .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
        .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
        .find_in_batches(:batch_size => 2500) do |items|
          ids = []
          items.each{ |i| ids << i['id'] }
          puts "ids are :: #{ids.inspect}"
          FactCheck.where(id: ids).update_all(language: language)
        end
        # log last team id
        Rails.cache.write('check:migrate:add_language_to_fact_check:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task add_report_information_to_fact_check: :environment do
      started = Time.now.to_i
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:add_report_information_to_fact_check:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.select('project_medias.id as id, fc.id as fc_id')
        .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
        .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
        .find_in_batches(:batch_size => 2500) do |items|
          print '.'
          pm_fc = {}
          items.each{ |i| pm_fc[i['id']] = i['fc_id'] }
          fc_fields = {}
          # Collect report designer
          Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: pm_fc.keys).find_each do |rd|
            print '.'
            # Get report status and publisher id
            state = rd.data['state']
            publisher_id =  state == 'published' ? rd.annotator_id : nil
            fc_fields[pm_fc[rd.annotated_id]] = { publisher_id: publisher_id, report_status: state }
          end
          # Add rating (depend on status cached field)
          ProjectMedia.where(id: pm_fc.keys).find_each do |pm|
            print '.'
            tags = pm.tags_as_sentence.split(',')
            fc_fields[pm_fc[pm.id]].merge!({ rating: pm.status, tags: tags })
          end
          fc_items = []
          FactCheck.where(id: pm_fc.values).find_each do |fc|
            fc_fields[fc.id].each { |field, value| fc.send("#{field}=", value) }
            fc_items << fc.attributes
          end
          FactCheck.upsert_all(fc_items)
        end
        # log last team id
        Rails.cache.write('check:migrate:add_report_information_to_fact_check:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end