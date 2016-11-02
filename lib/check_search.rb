class CheckSearch

  def initialize(options, context_team = nil)
    # options include keywords, projects, tags, status
    @options = JSON.parse(options)
    if @options["projects"].blank?
      @options["projects"] = context_team.projects.map(&:id) unless context_team.nil?
    end
    # set sort options
    @options['sort'] = @options['sort'] ||= 'recent_added'
    @options['sort_type'] = @options['sort_type'] ||= 'DESC'
  end

  def id
    Digest::MD5.hexdigest(@options.inspect)
  end

  def create
    # query_a to fetch keyword/context
    ids_sort = ids = build_search_query_a
    # query_b to fetch tags/categories
    unless @options["tags"].blank?
      result_ids = build_search_query_b
      # get intesect between query_a & query_b to get medias that match user options
      # which related to keywords, context, tags
      ids_sort = ids.keep_if { |k, _v| result_ids.key? k }
      if @options['sort'] == 'recent_activity'
        ids_sort.each{|k, _v| ids_sort[k] = [ids[k], result_ids[k]].max}
      end
    end
    # query_c to fetch status (final result)
    ids_sort = build_search_query_c(ids_sort) unless @options["status"].blank?
    check_search_sort(ids_sort)
  end

  def search_result
    self.create
  end

  def medias
    # should loop in search result and return media
    # for now all results are media
    self.search_result
  end

  private

  def build_search_query_a
    if @options["keyword"].blank?
      query = { match_all: {} }
    else
      query = { query_string: { query: @options["keyword"], fields:  %w(title description quote text) } }
    end
    filters = [{terms: { annotation_type: %w(embed comment) } } ]
    filters << {term: { annotated_type: "media"}}
    unless @options["projects"].blank?
      context_filters = [{terms: { context_id: @options["projects"] } } ]
      context_filters << {terms: { search_context: @options["projects"] } }
    end
    filter = { bool: { should: [ context_filters ] , must: [ filters ] } }
    get_query_result(query, filter)
  end

  def build_search_query_b
    query = { match_all: {} }
    filters = []
    filters << {terms: { tag: @options["tags"]}} unless @options["tags"].blank?
    filter = {bool: { should: filters  } }
    filter[:bool][:must] = { terms: { context_id: @options["projects"]} } unless @options["projects"].blank?
    get_query_result(query, filter)
  end

  def build_search_query_c(media_ids)
    query = { terms: { annotated_id: media_ids.keys } }
    filter = { bool: { must: [ {term: {annotation_type: "status" } } ] } }
    ids = get_query_result(query, filter)
    ids.each{|k, _v| ids[k] = [ids[k], media_ids[k]].max}
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
        aggs: {
          recent_activity: {
            top_hits: {
              sort: [ { created_at: { order: :desc } } ],
              _source: { include: [ "status"] },
              size: 1
              }
          }
        }
      }
    }

    ids = {}
    Annotation.search(query: q, aggs: g).response['aggregations']['annotated']['buckets'].each do |result|
      add_key = true
      if result[:recent_activity][:hits][:hits][0]["_source"].has_key?(:status)
        add_key = false unless @options['status'].include? result[:recent_activity][:hits][:hits][0]["_source"][:status]
      end
      ids[result['key']] = result[:recent_activity][:hits][:hits][0]["sort"][0] if add_key
    end
    ids
  end

  def check_search_sort(ids_sort)
    if @options['sort'] == 'recent_activity'
      ids = Array.new
      if @options['sort_type'].upcase == 'DESC'
        ids_sort = ids_sort.sort_by(&:reverse).reverse
      else
        ids_sort = ids_sort.sort_by(&:reverse)
      end
      ids_sort.each {|k, _v| ids << Media.find(k)}
    else
      ids = Media.where(id: ids_sort.keys).order(id: @options['sort_type'])
    end
    ids
  end

end
