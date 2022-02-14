def parse_conditions(args)
  condition = {}
  return condition if args.blank?
  args.each do |a|
    arg = a.split('&')
    arg.each do |pair|
      key, value = pair.split(':')
      condition.merge!({ key => value })
    end
  end
  condition
end

namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:sync_updated_at_field['slug:team_slug&updated_at:value']
    task sync_updated_at_field: :environment do |_t, args|
      started = Time.now.to_i
      condition = parse_conditions args.extras
      team_condition = {}
      team_condition = { slug: condition['slug'] } unless condition['slug'].blank?
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      options = { index: index_alias }
      sort = [{ annotated_id: { order: :asc } }]
      Team.where(team_condition).find_each do |t|
        print '.'
        print "Processing team [#{t.slug}]"
        updated_at_condition = condition['updated_at'].blank? ? t.created_at : condition['updated_at'].to_datetime
        query = {
          bool: { 
            must: [
              { term: { team_id: { value: t.id } } },
              { 
                range: {
                  updated_at: {
                    gte: updated_at_condition.strftime("%Y-%m-%d"),
                    format: "yyyy-MM-dd"
                  }
                }
              }
            ]
          }
        }
        search_after = [0]
        while true
          es_updated_at = {}
          result = $repository.search(query: query, sort: sort, search_after: search_after, size: 5000)
          result.each{ |i| es_updated_at[i['annotated_id']] = i['updated_at'] }
          break if es_updated_at.blank?
          # Update PG with updated at value
          updated_items = []
          es_updated_at.each do |k, v|
            pg_item = ProjectMedia.new
            pg_item.id = k
            pg_item.updated_at = v
            updated_items << pg_item
          end
          # Import items with existing ids to make update
          imported = ProjectMedia.import(updated_items, recursive: false, validate: false, on_duplicate_key_update: [:updated_at])
          search_after = [es_updated_at.keys.max]
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
