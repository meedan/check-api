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
    # bundle exec rails check:migrate:index_fact_check_fields['slug:team_slug&batch_size:batch_size']
    task index_fact_check_fields: :environment do |_t, args|
      # This rake task to index the following fields
      # 1) claim_description [content, context]
      # 2) fact_check [title, summary, url, language]
      started = Time.now.to_i
      data_args = parse_args args.extras
      batch_size = data_args['batch_size'] || 500
      batch_size = batch_size.to_i
      # Add team condition
      slug = data_args['slug']
      team_condition = {}
      if slug.blank?
        last_team_id = Rails.cache.read('check:migrate:index_fact_check_fields:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: slug }
      end
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        team.claim_descriptions.joins(:project_media).find_in_batches(:batch_size => batch_size) do |cds|
          es_body = []
          ids = cds.map(&:id)
          ClaimDescription.select('claim_descriptions.project_media_id as pm_id, claim_descriptions.description, claim_descriptions.context, fact_checks.*')
          .where(id: ids)
          .joins(:fact_check)
          .find_in_batches(:batch_size => batch_size) do |items|
            print '.'
            items.each do |item|
              doc_id = Base64.encode64("ProjectMedia/#{item['pm_id']}")
              fields = {
                'claim_description_content' => item['description'],
                'claim_description_context' => item['context'],
                'fact_check_title' => item['title'],
                'fact_check_summary' => item['summary'],
                'fact_check_url' => item['url'],
                'fact_check_languages' => [item['language']]
              }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_fact_check_fields:team_id', team.id) if slug.blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task index_item_source_name: :environment do
      # This rake task to index source name
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_item_source_name:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 1000) do |pms|
          es_body = []
          ids = pms.map(&:id)
          ProjectMedia.select('project_medias.id as id, sources.name as name')
          .where(id: ids)
          .joins(:source)
          .find_in_batches(:batch_size => 1000) do |items|
            print '.'
            items.each do |item|
              doc_id = Base64.encode64("ProjectMedia/#{item['id']}")
              fields = { 'source_name' => item['name'] }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_item_source_name:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task initiate_item_requests: :environment do
      # This rake task to index source name
      started = Time.now.to_i
      client = $repository.client
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        conflicts: 'proceed'
      }
      last_team_id = Rails.cache.read('check:migrate:initiate_item_requests:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        print '.'
        body = {
          script: {
            source: "ctx._source.requests = params.requests", params: { requests: [] }
          },
          query: { term: { team_id: team.id } }
        }
        options[:body] = body
        client.update_by_query options
        Rails.cache.write('check:migrate:initiate_item_requests:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task index_item_requests: :environment do
      # This rake task to index item requests
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_item_requests:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team #{team.slug} ...."
        team.project_medias.find_in_batches(:batch_size => 500) do |pms|
          ids = pms.map(&:id)
          # collect requests
          pm_requests = Hash.new {|hash, key| hash[key] = [] }
          DynamicAnnotation::Field
          .select('dynamic_annotation_fields.id as id, dynamic_annotation_fields.value_json as value_json, a.annotated_id as pm_id')
          .where(field_name: 'smooch_data')
          .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
          .where('a.annotated_type = ? and a.annotated_id IN (?)', 'ProjectMedia', ids)
          .find_each do |field|
            print '.'
            pm_requests[field.pm_id] << {
              id: field.id,
              username: field.value_json['name'],
              identifier: Rails.cache.read("smooch:user:external_identifier:#{field.value_json['authorId']}")&.gsub(/[[:space:]|-]/, ''),
              content: field.value_json['text'],
            }
          end
          es_body = []
          pm_requests.each do |k, v|
            unless v.blank?
              doc_id = Base64.encode64("ProjectMedia/#{k}")
              fields = { "requests" => v }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_item_requests:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
