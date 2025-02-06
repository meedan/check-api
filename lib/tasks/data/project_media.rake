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
      def self.task_responses(team, pm_ids)
        pm_responses = Hash.new {|hash, key| hash[key] = [] }
        ProjectMedia.where(id: pm_ids).find_each do |obj|
          output = []
          tasks = obj.annotations('task')
          if tasks.length > 0
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
          end
          pm_responses[obj.id] = output
        end
        pm_responses
      end

      def self.tags(_team, pm_ids)
        pm_tags = Hash.new {|hash, key| hash[key] = [] }
        Tag.where(annotation_type: 'tag', annotated_id: pm_ids, annotated_type: 'ProjectMedia')
        .find_each do |t|
          pm_tags[t.annotated_id] << {
            id: t.id,
            tag: t.tag_text
          }
        end
        pm_tags
      end

      def self.requests(_team, pm_ids)
        pm_requests = Hash.new {|hash, key| hash[key] = [] }
        DynamicAnnotation::Field.select("dynamic_annotation_fields.id, dynamic_annotation_fields.value_json, annotations.annotated_id as pm_id")
        .joins(:annotation)
        .where(
          field_name: 'smooch_data',
          'annotations.annotated_id' => pm_ids,
          'annotations.annotation_type' => 'smooch',
          'annotations.annotated_type' => 'ProjectMedia'
          )
        .find_each do |field|
          author_id = field.value_json['authorId']
          identifier = begin Rails.cache.read("smooch:user:external_identifier:#{author_id}").value rescue Rails.cache.read("smooch:user:external_identifier:#{author_id}") end
          pm_requests[field.pm_id] << {
            id: field.id,
            username: field.value_json['name'],
            identifier: identifier&.gsub(/[[:space:]|-]/, ''),
            content: field.value_json['text'],
            language: field.value_json['language'],
          }
        end
        pm_requests
      end
    end
    # bundle exec rails check:project_media:recalculate_cached_field['slug:team_slug&field:field_name']
    task recalculate_cached_field: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      field_name = data_args['field']
      raise "You must set field name as args for rake task Aborting." if field_name.blank?
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
          end
          sleep 2
        end
        Rails.cache.write('check:project_media:recalculate_cached_field:team_id', team.id) if data_args['slug'].blank?
        sleep 5
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
        last_team_id = Rails.cache.read("check:project_media:sync_es_field:#{field_name}:team_id") || 0
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
        Rails.cache.write("check:project_media:sync_es_field:#{field_name}:team_id", team.id) if data_args['slug'].blank?
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
      # Add Team condition
      team_condition = {}
      if data_args['slug'].blank?
        last_team_id = Rails.cache.read("check:project_media:sync_es_nested_field:#{field_name}:team_id") || 0
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
        print '.'
        team.project_medias.where(pm_condition).find_in_batches(:batch_size => 100) do |pms|
          es_body = []
          pms_data = HandleNestedField.send(field_name, team, pms.map(&:id))
          pms_data.each do |pm_id, value|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{pm_id}")
            fields = { "#{field_name}" => value }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          $repository.client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write("check:project_media:sync_es_nested_field:#{field_name}:team_id", team.id) if data_args['slug'].blank?
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
        last_team_id = Rails.cache.read('check:project_media:index_pg_items:team_id') || 0
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
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.where(pm_condition).find_in_batches(:batch_size => 1000) do |pms|
          pms.each do |obj|
            print '.'
            obj.create_elasticsearch_doc_bg({ force_creation: true })
          end
        end
        Rails.cache.write('check:project_media:index_pg_items:team_id', team.id) if data_args['slug'].blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
