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

    task fix_parent_id_and_sources_count_for_suggested_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml)
      .find_in_batches(:batch_size => 2500) do |items|
        # Update PG
        ids = items.map(&:target_id)
        ProjectMedia.where(id: ids).update_all(sources_count: 0)
        # Update ES
        es_body = []
        items.each do |item|
          print '.'
          doc_id =  Base64.encode64("ProjectMedia/#{item.target_id}")
          fields = { 'parent_id' => item.target_id, 'sources_count' => 0 }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task fix_parent_id_and_sources_count_for_confirmed_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml)
      .find_in_batches(:batch_size => 2500) do |items|
        ids = items.map(&:target_id)
        target_count = Relationship.where(target_id: ids)
        .where('relationship_type = ?', Relationship.confirmed_type.to_yaml).group(:target_id).count
        # Update PG with sources_count value
        updated_items = []
        target_count.each do |k, v|
          pg_item = ProjectMedia.new
          pg_item.id = k
          pg_item.sources_count = v
          updated_items << pg_item
        end
        # Import items with existing ids to make update
        imported = ProjectMedia.import(updated_items, recursive: false, validate: false, on_duplicate_key_update: [:sources_count])
        # Update ES
        es_body = []
        items.each do |item|
          print '.'
          target_id = item.target_id
          doc_id =  Base64.encode64("ProjectMedia/#{target_id}")
          fields = { 'parent_id' => item.source_id, 'sources_count' => target_count[target_id] }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:migrate:fix_parent_id_for_suggested_list['slug:team_slug&ids:1-2-3']
    task fix_parent_id_for_suggested_list: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      pm_ids = []
      pm_ids = begin ids.split('-').map{ |s| s.to_i } rescue [] end
      # Add Team condition
      team_condition = {}
      if data_args['slug'].blank?
        last_team_id = Rails.cache.read('check:migrate:fix_parent_id_for_suggested_list:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: data_args['slug'] }
      end
      index_alias = CheckElasticSearchModel.get_index_alias
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        result_ids = CheckSearch.new({"suggestions_count"=>{"min"=>1}}.to_json, nil, team.id).medias.map(&:id)
        result_ids.concat(pm_ids) unless pm_ids.blank?
        # Confirmed items
        Relationship.where(source_id: result_ids, relationship_type: Relationship.confirmed_type).find_in_batches(:batch_size => 1000) do |relations|
          es_body = []
          # Update parent_id for sources
          source_ids = relations.map(&:source_id).uniq
          source_ids.each do |source_id|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{source_id}")
            fields = { "parent_id" => source_id }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          relations.each do |r|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{r.target_id}")
            fields = { "parent_id" => r.source_id }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          $repository.client.bulk body: es_body unless es_body.blank?
        end
        # Suggested items
        Relationship.where(source_id: result_ids, relationship_type: Relationship.suggested_type).find_in_batches(:batch_size => 1000) do |relations|
          es_body = []
          relations.each do |r|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{r.target_id}")
            fields = { "parent_id" => r.target_id }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          $repository.client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:fix_parent_id_for_suggested_list:team_id', team.id) if data_args['slug'].blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end