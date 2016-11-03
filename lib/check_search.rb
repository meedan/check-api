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
    ids = ids_a = build_search_query_a
    # query_b to fetch tags/categories
    unless @options["tags"].blank?
      ids_b = build_search_query_b
      # get intesect between query_a & query_b to get medias that match user options
      # which related to keywords, context, tags
      ids = ids_a.keep_if { |k, _v| ids_b.key? k }
      ids = fetch_media_projects(ids, ids_a, ids_b)
    end
    # query_c to fetch status (final result)
    ids = build_search_query_c(ids) unless @options["status"].blank?
    check_search_sort(ids)
  end

  def search_result
    self.create
  end

  def medias
    # should loop in search result and return media
    # for now all results are medias
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
    get_search_result(query, filter)
  end

  def build_search_query_b
    query = { match_all: {} }
    filters = []
    filters << {terms: { tag: @options["tags"]}} unless @options["tags"].blank?
    filter = {bool: { should: filters  } }
    filter[:bool][:must] = { terms: { context_id: @options["projects"]} } unless @options["projects"].blank?
    get_search_result(query, filter)
  end

  def build_search_query_c(media_ids)
    query = { terms: { annotated_id: media_ids.keys } }
    filter = { bool: { must: [ {term: {annotation_type: "status" } } ] } }
    ids = get_search_result(query, filter)
    ids_p = fetch_media_projects(ids, ids, media_ids)
    ids_p
  end

  def get_search_result(query, filter)
    q, g = build_search_query(query, filter)
    ids = {}
    Annotation.search(query: q, aggs: g).response['aggregations']['annotated']['buckets'].each do |result|
      context_ids = {}
      result[:context][:buckets].each do |context|
        add_key = true
        if context[:recent_activity][:hits][:hits][0][:_source].has_key?(:status)
          unless @options['status'].include? context[:recent_activity][:hits][:hits][0][:_source][:status]
            add_key = false
          end
        end
        if add_key
          if context['key'] == 'no_key'
            context[:recent_activity][:hits][:hits][0][:_source][:search_context].each do |sc|
              context_ids[sc] = context[:recent_activity][:hits][:hits][0][:sort][0]
            end
          else
            context_ids[context['key']] = context[:recent_activity][:hits][:hits][0][:sort][0]
          end
        end
      end
      ids[result['key']] = context_ids unless context_ids.blank?
    end
    ids
  end

  def build_search_query(query, filter)
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
          context: {
            terms: { field: :context_id, missing: :no_key },
              aggs: {
                recent_activity: {
                  top_hits: {
                    sort: [ { created_at: { order: :desc } } ],
                    _source: { include: %w(status context_id search_context) },
                    size: 1
                  }
                }
              }
            }
          }
        }
    }
    return q, g
  end

  def fetch_media_projects(ids, ids_a, ids_b)
    ids_p = {}
    ids.each do |k, _v|
      v_a = ids_a[k]; v_b = ids_b[k]
      ids_p[k] = v_a.keep_if { |kp, _vp| v_b.key? kp }
      ids_p[k].each{|km, _vm| ids_p[k][km] = [v_a[km], v_b[km]].max}
    end
    ids_p
  end

  def check_search_sort(ids)
    ids = prepare_ids_for_sort(ids)
    ids_sort = Array.new
    if @options['sort_type'].upcase == 'DESC'
      ids = ids.sort_by(&:reverse).reverse
    else
      ids = ids.sort_by(&:reverse)
    end
    ids.each do |k, _v|
      p, m = k.split('-')
      media = Media.find(m.to_i)
      media.project_id = p.to_i
      ids_sort << media
    end
    ids_sort
  end

  def prepare_ids_for_sort(ids)
    result = {}
    ids.each do |m, v|
      v.each do |p, t|
        pm = [p, m].join('-')
        t = m if @options['sort'] == 'recent_added'
        result[pm] = t
      end
    end
    result
  end

end
