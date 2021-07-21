namespace :check do
  # bundle exec rake check:create_es_data_from_pg[team_slug1, team_slug2, ...]
  desc "Create ES data from PG"
  task create_es_data_from_pg: :environment do |_t, args|
    started = Time.now.to_i
    slugs = args.extras
    if slugs.blank?
      begin
        MediaSearch.delete_index
        MediaSearch.create_index
      rescue Exception => e
        puts "You must delete the existing index or alias [#{CheckElasticSearchModel.get_index_alias}] before running the task."
      end
    end
    index_pg_data(slugs)
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end

  def index_pg_data(slugs)
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      conflicts: 'proceed'
    }
    condition = {}
    condition = { slug: slugs } unless slugs.blank?
    # Add ES doc
    Team.where(condition).find_each do |team|
      # delete existing items in case user create items per team
      options[:body] = { query: { term: { team_id: { value: team.id } } } }
      client.delete_by_query options
      team.project_medias.find_each do |obj|
        obj.create_elasticsearch_doc_bg({})
        print '.'
      end
    end

    sleep 20
    failures = []
    # append nested objects
    Team.where(condition).find_each do |team|
      team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
        es_body = []
        pms.each do |obj|
          print '.'
          doc_id = Base64.encode64("ProjectMedia/#{obj.id}")
          data = {}
          updated_at = []
          # comments
          comments = obj.annotations('comment')
          data['comments'] = comments.collect{|c| {id: c.id, text: c.text}}
          # get maximum updated_at for recent_acitivty sort
          max_updated_at = comments.max_by(&:updated_at)
          updated_at << max_updated_at.updated_at unless max_updated_at.nil?
          # tags
          tags = obj.get_annotations('tag').map(&:load)
          data['tags'] = tags.collect{|t| {id: t.id, tag: t.tag_text}}
          max_updated_at = tags.max_by(&:updated_at)
          updated_at << max_updated_at.updated_at unless max_updated_at.nil?
          # Dynamics
          dynamics = []
          obj.annotations.where("annotation_type LIKE 'task_response%'").find_each do |d|
            d = d.load
            options = d.get_elasticsearch_options_dynamic
            dynamics << d.store_elasticsearch_data(options[:keys], options[:data])
            updated_at << d.updated_at
          end
          data['dynamics'] = dynamics
          tasks = obj.annotations('task')
          tasks_ids = tasks.map(&:id)
          # 'task_responses'
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

          # 'task_comments'
          task_comments = Annotation.where(annotation_type: 'comment', annotated_type: 'Task', annotated_id: tasks_ids)
          data['task_comments'] = task_comments.collect{|c| {id: c.id, text: c.text}}
          max_updated_at = task_comments.max_by(&:updated_at)
          updated_at << max_updated_at.updated_at unless max_updated_at.nil?
          # 'assigned_user_ids'
          assignments_uids = Assignment.where(assigned_type: ['Annotation', 'Dynamic'])
          .joins('INNER JOIN annotations a ON a.id = assignments.assigned_id')
          .where('a.annotated_type = ? AND a.annotated_id = ?', 'ProjectMedia', obj.id).map(&:user_id)
          data['assigned_user_ids'] = assignments_uids.uniq
          # recent_activity date
          data['updated_at'] = updated_at.max
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
        end
        response = client.bulk body: es_body unless es_body.blank?
        if response['errors']
          response['items'].select { |i| i.dig('error') }.each do |item|
            update = item['update']
            failures << { doc_id: update['_id'], status: update['status'], error: update['error']['type'] }
          end
        end
      end
    end
    if failures.size > 0
      puts "Failed to index #{failed_items.size} items"
      Rails.cache.write('check:migrate:create_es_data_from_pg:failures', failures)
      pp failed_items
    end
  end
end
