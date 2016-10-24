class CheckSearch


  def create(options)
    # search will include keywords, projects, tags, status, categories
    options = JSON.parse(options)
    # query_a to fetch keyword/context
    ids = build_search_query_a(options)
    # query_b to fetch tags/categories
    unless options["tags"].blank?
      result_ids = build_search_query_b(options)
      # get intesect between query_a & query_b to get medias that match user options
      # which related to keywords, context, tags
      ids = ids & result_ids
    end
    # query_c to fetch status
    unless options["status"].blank?
      ids = build_search_query_c(ids, options["status"])
    end
    result = Array.new
    ids.each {|id| result << Media.find(id)}
    result
  end

  def build_search_query_a(options)
    if options["keyword"].blank?
      query = { match_all: {} }
    else
      query = { query_string: { query: options["keyword"], fields:  %w(title description quote) } }
    end
    filters = [{"term": { "annotation_type": "embed"}}]
    filters << {"term": { "annotated_type": "media"}}
    filters << {"terms": { "context_id": options["project"]}} unless options["project"].blank?
    filter = { bool: { must: [ filters ] } }
    get_query_result(query, filter)
  end

  def build_search_query_b(options)
    query = { match_all: {} }
    filters = Array.new
    filters << [{"terms": { "tag": options["tags"]}}] unless options["tags"].blank?
    filter = {bool: { should: filters  } }
    filter[:bool][:must] = { "terms": {"context_id": options["project"]} } unless options["project"].blank?
    get_query_result(query, filter)
  end

  def build_search_query_c(media_ids, status)
    Rails.logger.debug("Calling status query #{media_ids}")
    q = {
      filtered: {
        query: { terms: { annotated_id: media_ids } },
       filter: { bool: { must: [ {term: {annotation_type: "status" } } ] } }
     }
   }
   g = {
    annotated: {
        terms: { field: :annotated_id},
        aggs: {
          latest_status: {
            top_hits: {
              sort: [ { created_at: { order: :desc} } ],
              _source: { "include": [ "status"] },
              size: 1
            }
          }
        }
      }
    }
    ids = []
    Annotation.search(query: q, aggs: g).response['aggregations']['annotated']['buckets'].each do |result|
      if status.include? result[:latest_status][:hits][:hits][0]["_source"][:status]
        ids << result['key']
      end
    end
    ids
  end

  def get_query_result(query, filter)
    q = {
      filtered: {
        query: query,
        filter: filter
      }
    }
    g = {
      annotated: {
        terms: { field: :annotated_id },
        aggs: { type: { terms: { field: :annotated_type } } }
      }
    }
    ids = []
    Annotation.search(query: q, aggs: g).response['aggregations']['annotated']['buckets'].each do |result|
      ids << result['key']
    end
    ids
  end

end
