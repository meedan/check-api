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

# These rake tasks to handle sync fields related to ProjectMedia betwwen PG & ES
# 1-bundle exec rails check:project_media:recalculate_cached_field['slug:team_slug&field:field_name']
#     This rake task to sync cached field and accept teamSlug and fieldName as args so the sync either
#     by team or accross all teams
# 2-bundle exec rails check:project_media:recalculate_cluster_cached_field['field']
#     This rake task to sync cluster cached field and accept field name as args
# 3-bundle exec rails check:project_media:sync_pg_field['slug:team_slug&field:field_name']
#     This rake task to sync PG field and accept teamSlug and fieldName as args so the sync either
#     by team or accross all teams

namespace :check do
  namespace :project_media do
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
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
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

    # bundle exec rails check:project_media:sync_pg_field['slug:team_slug&field:field_name']
    task sync_pg_field: :environment do |_t, args|
      data_args = parse_args args.extras
      started = Time.now.to_i
      field_name = data_args['field']
      raise "You must set field name as args for rake task Aborting." if field_name.blank? || !ProjectMedia.new.respond_to?(field_name)
      # TODO: add mapping if PG field name not same as ES field name
      es_fields_mapping = {
        'status' => 'verification_status'
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
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            value = pm.send(field_name)
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
            field_i = ['archived', 'sources_count', 'linked_items_count', 'share_count','last_seen', 'demand', 'user_id', 'read']
            field_value = if field_name == 'channel'
                            value.values.flatten.map(&:to_i)
                          elsif field_i.include?(field_name)
                            value.to_i
                          else
                            value
                          end
            fields = { "#{es_field_name}" => field_value }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:project_media:sync_pg_field:team_id', team.id) if data_args['slug'].blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
