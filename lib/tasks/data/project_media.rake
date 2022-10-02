# These rake tasks to handle sync fields related to ProjectMedia betwwen PG & ES
# 1-bundle exec rails check:project_media:recalculate_cached_field['slug:team_slug&field:field_name&ids:pm_ids']
#     This rake task to sync cached field and accept teamSlug and fieldName as args so the sync either
#     by team or accross all teams
# 2-bundle exec rails check:project_media:recalculate_cluster_cached_field['field']
#     This rake task to sync cluster cached field and accept field name as args
# 3-bundle exec rails check:project_media:sync_es_field['slug:team_slug&field:field_name&ids:pm_ids']
#     This rake task to sync PG field and accept teamSlug and fieldName as args so the sync either
#     by team or accross all teams
# 4-bundle exec rails check:project_media:sync_es_nested_field['slug:team_slug&field:field_name&ids:pm_ids']
#     This rake task to sync ES nested field and accept teamSlug and fieldName as args so the sync either
#     by team or accross all teams
# Rake tasks 1, 3 and 4 accept extra args
#   - ids as args and should be with `-` separator, i.e ids:1-2-3
#   - start_date i.e start_date='12-04-1983'
#   - end_date i.e end_date=12-04-1983

namespace :check do
  namespace :project_media do
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

    class HandleNestedField
      def self.task_responses(team, obj)
        output = []
        tasks = obj.annotations('task')
        return output if tasks.length == 0
        tasks_ids = tasks.map(&:id)
        team_task_ids = TeamTask.where(team_id: team.id).map(&:id)
        responses = Task.where('annotations.id' => tasks_ids)
        .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', team_task_ids)
        .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
          AND responses.annotated_type = 'Task'
          AND responses.annotated_id = annotations.id"
          )
        output = responses.collect{ |tr| {
            id: tr.id,
            fieldset: tr.fieldset,
            field_type: tr.type,
            team_task_id: tr.team_task_id,
            value: tr.first_response
          }
        }
        # add TeamTask of type choice with no answer
        no_response_ids = tasks_ids - responses.map(&:id)
        Task.where(id: no_response_ids)
        .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', team_task_ids).find_each do |item|
          if item.type =~ /choice/
            output << { id: item.id, team_task_id: item.team_task_id, fieldset: item.fieldset }
          end
        end
        output
      end

      def self.comments(_team, obj)
        comments = obj.annotations('comment')
        comments.collect{|c| {id: c.id, text: c.text}}
      end

      def self.tags(_team, obj)
        tags = obj.get_annotations('tag').map(&:load)
        tags.collect{|t| {id: t.id, tag: t.tag_text}}
      end

      def self.accounts(_team, obj)
        a = obj.media.account
        return [] if a.blank?
        metadata = a.metadata || {}
        [{
          id: a.id,
          title: metadata['title'],
          description: metadata['description'],
        }]
      end
    end
    # bundle exec rails check:project_media:recalculate_cached_field['slug:team_slug&field:field_name']
    task recalculate_cached_field: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      field_name = data_args['field']
      raise "You must set field name as args for rake task Aborting." if field_name.blank?
      es_fields_mapping = {
        'title' => 'title_index',
        'status' => 'status_index'
      }
      es_field_name = es_fields_mapping[field_name].blank? ? field_name : es_fields_mapping[field_name]
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # Add team condition
      team_condition = {}
      if data_args['slug'].blank?
        last_team_id = Rails.cache.read('check:project_media:recalculate_cached_field:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: data_args['slug'] } unless data_args['slug'].blank?
      end
      # Add ProjectMedia condition
      pm_condition = {}
      unless data_args['ids'].blank?
        pm_ids = begin data_args['ids'].split('-').map{ |s| s.to_i } rescue [] end
        pm_condition = { id: pm_ids } unless pm_ids.blank?
      end
      # Add date condition
      unless data_args['start_date'].blank? && data_args['end_date'].blank?
        start_date = begin DateTime.parse(data_args['start_date']) rescue Team.first.created_at end
        end_date = begin DateTime.parse(data_args['end_date']) rescue Time.now end
        pm_condition[:created_at] = start_date..end_date
      end
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.where(pm_condition).find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            value = pm.send(field_name, true)
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
            field_value = if field_name == 'report_status'
                            ['unpublished', 'paused', 'published'].index(value)
                          elsif field_name == 'status'
                            pm.status_ids.index(value)
                          elsif field_name == 'tags_as_sentence'
                            value.split(', ').size
                          elsif field_name == 'published_by'
                            value.keys.first || 0
                          elsif field_name == 'type_of_media'
                            Media.types.index(value)
                          else
                            value
                          end
            fields = { "#{es_field_name}" => field_value }
            # add extra fields to ES
            if field_name == 'title'
              fields["title"] = field_value
            elsif field_name == 'status'
              fields["verification_status"] = pm.status
            end
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:project_media:recalculate_cached_field:team_id', team.id) if data_args['slug'].blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:project_media:recalculate_cluster_cached_field[field]
    task recalculate_cluster_cached_field: :environment do |_t, args|
      started = Time.now.to_i
      field_name = args.extras.last
      raise "You must set field name as args for rake task Aborting." if field_name.blank?
      es_fields_mapping = {
        'team_names' => 'cluster_teams',
        'fact_checked_by_team_names' => 'cluster_published_reports',
        'requests_count' => 'cluster_requests_count'
      }
      es_field_name = es_fields_mapping[field_name].blank? ? field_name : es_fields_mapping[field_name]
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Cluster.find_in_batches(:batch_size => 2500) do |clusters|
        es_body = []
        clusters.each do |c|
          print '.'
          value = c.send(field_name, true)
          doc_id = Base64.encode64("ProjectMedia/#{c.project_media_id}")
          field_value = value
          if ['cluster_teams', 'cluster_published_reports'].include?(es_field_name)
            field_value = value.keys
          end
          fields = { "#{es_field_name}" => field_value }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:project_media:sync_es_field['slug:team_slug&field:field_name']
    task sync_es_field: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      field_name = data_args['field']
      raise "You must set field name as args for rake task Aborting." if field_name.blank? || !ProjectMedia.new.respond_to?(field_name)
      # TODO: add mapping if PG field name not same as ES field name
      es_fields_mapping = {
        'title' => 'title_index',
        'status' => 'status_index'
      }
      es_field_name = es_fields_mapping[field_name].blank? ? field_name : es_fields_mapping[field_name]
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # Add team condition
      team_condition = {}
      if data_args['slug'].blank?
        last_team_id = Rails.cache.read('check:project_media:sync_pg_field:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: data_args['slug'] } unless data_args['slug'].blank?
      end
      # Add ProjectMedia condition
      pm_condition = {}
      unless data_args['ids'].blank?
        pm_ids = begin data_args['ids'].split('-').map{ |s| s.to_i } rescue [] end
        pm_condition = { id: pm_ids } unless pm_ids.blank?
      end
      # Add date condition
      unless data_args['start_date'].blank? && data_args['end_date'].blank?
        start_date = begin DateTime.parse(data_args['start_date']) rescue Team.first.created_at end
        end_date = begin DateTime.parse(data_args['end_date']) rescue Time.now end
        pm_condition[:created_at] = start_date..end_date
      end

      field_i = [
        'team_id', 'project_id', 'archived', 'sources_count', 'user_id',
        'read', 'linked_items_count', 'last_seen', 'share_count', 'demand',
        'reaction_count', 'comment_count', 'related_count', 'suggestions_count',
        'source_id'
      ]
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.where(pm_condition).find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            value = pm.send(field_name) if pm.respond_to?(field_name)
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")

            field_value = if field_name == 'report_status'
                            ['unpublished', 'paused', 'published'].index(value)
                          elsif field_name == 'status'
                            pm.status_ids.index(value)
                          elsif field_name == 'tags_as_sentence'
                            value.split(', ').size
                          elsif field_name == 'published_by'
                            value.keys.first || 0
                          elsif field_name == 'type_of_media'
                            Media.types.index(value)
                          elsif field_name == 'channel'
                            value.values.flatten.map(&:to_i)
                          elsif field_i.include?(field_name)
                            value.to_i
                          else
                            value
                          end

            fields = { "#{es_field_name}" => field_value }
            # add extra fields to ES
            if field_name == 'title'
              fields["title"] = field_value
            elsif field_name == 'status'
              fields["verification_status"] = pm.status
            end
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:project_media:sync_pg_field:team_id', team.id) if data_args['slug'].blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:project_media:sync_es_nested_field['slug:team_slug&field:field_name']
    task sync_es_nested_field: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      field_name = data_args['field']
      raise "You must set field name as args for rake task Aborting." if field_name.blank?
      raise "No mapping for this field Aborting." unless HandleNestedField.respond_to?(field_name)
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # Add Team condition
      team_condition = {}
      if data_args['slug'].blank?
        last_team_id = Rails.cache.read('check:project_media:sync_es_nested_field:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: data_args['slug'] } unless data_args['slug'].blank?
      end
      # Add ProjectMedia condition
      pm_condition = {}
      unless data_args['ids'].blank?
        pm_ids = begin data_args['ids'].split('-').map{ |s| s.to_i } rescue [] end
        pm_condition = { id: pm_ids } unless pm_ids.blank?
      end
      # Add date condition
      unless data_args['start_date'].blank? && data_args['end_date'].blank?
        start_date = begin DateTime.parse(data_args['start_date']) rescue Team.first.created_at end
        end_date = begin DateTime.parse(data_args['end_date']) rescue Time.now end
        pm_condition[:created_at] = start_date..end_date
      end

      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.where(pm_condition).find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            value = HandleNestedField.send(field_name, team, pm)
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
            fields = { "#{field_name}" => value }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:project_media:sync_es_nested_field:team_id', team.id) if data_args['slug'].blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # bundle exec rails check:project_media:index_pg_items['slug:team_slug&ids:1-2-3']
    task index_pg_items: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      # Add Team condition
      team_condition = {}
      if data_args['slug'].blank?
        last_team_id = 0 #Rails.cache.read('check:project_media:index_pg_items:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: data_args['slug'] } unless data_args['slug'].blank?
      end
      # Add ProjectMedia condition
      pm_condition = {}
      unless data_args['ids'].blank?
        pm_ids = begin data_args['ids'].split('-').map{ |s| s.to_i } rescue [] end
        pm_condition = { id: pm_ids } unless pm_ids.blank?
      end
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      options = {
        index: index_alias,
        conflicts: 'proceed'
      }
      failures = []
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.where(pm_condition).find_in_batches(:batch_size => 1000) do |pms|
          # delete existing items.
          options[:body] = { query: { terms: { annotated_id: pms.map(&:id) } } }
          client.delete_by_query options
          es_body = []
          pms.each do |obj|
            print '.'
            obj.create_elasticsearch_doc_bg({})
            # append nested objects
            doc_id = Base64.encode64("ProjectMedia/#{obj.id}")
            data = {}
            # comments
            comments = obj.annotations('comment')
            data['comments'] = comments.collect{|c| {id: c.id, text: c.text}}
            # tags
            tags = obj.get_annotations('tag').map(&:load)
            data['tags'] = tags.collect{|t| {id: t.id, tag: t.tag_text}}
            # 'task_responses'
            tasks = obj.annotations('task')
            tasks_ids = tasks.map(&:id)
            team_task_ids = TeamTask.where(team_id: team.id).map(&:id)
            responses = Task.where('annotations.id' => tasks_ids)
            .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', team_task_ids)
            .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
              AND responses.annotated_type = 'Task'
              AND responses.annotated_id = annotations.id"
              )
            data['task_responses'] = responses.collect{ |tr| {
                id: tr.id,
                fieldset: tr.fieldset,
                field_type: tr.type,
                team_task_id: tr.team_task_id,
                value: tr.first_response
              }
            }
            # add TeamTask of type choice with no answer
            no_response_ids = tasks_ids - responses.map(&:id)
            Task.where(id: no_response_ids)
            .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', team_task_ids).find_each do |item|
              if item.type =~ /choice/
                data['task_responses'] << { id: item.id, team_task_id: item.team_task_id, fieldset: item.fieldset }
              end
            end
            # 'assigned_user_ids'
            assignments_uids = Assignment.where(assigned_type: ['Annotation', 'Dynamic'])
            .joins('INNER JOIN annotations a ON a.id = assignments.assigned_id')
            .where('a.annotated_type = ? AND a.annotated_id = ?', 'ProjectMedia', obj.id).map(&:user_id)
            data['assigned_user_ids'] = assignments_uids.uniq
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
          end
          sleep 20
          response = client.bulk body: es_body unless es_body.blank?
          if response['errors']
            response['items'].select { |i| i.dig('error') }.each do |item|
              update = item['update']
              failures << { doc_id: update['_id'], status: update['status'], error: update['error']['type'] }
            end
          end
        end
        Rails.cache.write('check:project_media:index_pg_items:team_id', team.id) if data_args['slug'].blank?
      end
      if failures.size > 0
        puts "Failed to index #{failed_items.size} items"
        Rails.cache.write('check:project_media:index_pg_items:failures', failures)
        pp failed_items
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
