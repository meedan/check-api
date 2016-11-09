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
    Base64.encode64("CheckSearch/#{@options.to_json}")
  end

  def create
    # query_a to fetch keyword/context
    ids = {}
    if @options["keyword"].blank? and @options["tags"].blank? and @options["status"].blank?
      ids = build_search_query_a
    else
      ids_a = build_search_query_a unless @options["keyword"].blank?
      ids_b = build_search_query_b unless @options["tags"].blank?
      if !ids_a.blank? and !ids_b.blank?
        ids = ids_a.keep_if { |k, _v| ids_b.key? k }
        ids = fetch_media_projects(ids, ids_a, ids_b)
      elsif !ids_a.blank?
        ids = ids_a
      elsif !ids_b.blank?
        ids = ids_b
      end
    end
    # query_c to fetch status
    unless @options["status"].blank?
      ids_c = build_search_query_c(ids)
      if !ids.blank? and !ids_c.blank?
        ids = ids.keep_if { |k, _v| ids_c.key? k }
        ids = fetch_media_projects(ids, ids, ids_c)
      elsif !ids_c.blank?
        ids = ids_c
      end
    end
    # query to collect latest timestamp for media activities
    ids = build_search_query_recent_activity(ids) if self.allow_sort_by_recent_activity?
    check_search_sort(ids)
  end

  def search_result
    self.create
  end

  def medias
    # should loop in search result and return media
    # for now all results are medias
    @search_result ||= self.search_result
  end

  def number_of_results
    self.medias.count
  end

  protected

  def should_add_key?(context)
    add_key = true
    unless @options['status'].blank?
      if context[:recent_activity][:hits][:hits][0][:_source].has_key?(:status) && !@options['status'].include?(context[:recent_activity][:hits][:hits][0][:_source][:status])
        add_key = false
      end
    end
    add_key
  end

  def get_search_buckets(query, aggs)
    Annotation.search(query: query, aggs: aggs, size: 10000).response['aggregations']['annotated']['buckets']
  end

  def allow_sort_by_recent_activity?
    if @options['sort'] == 'recent_activity'
      return true if @options["status"].blank? or @options["tags"].blank? or !@options["keyword"].blank?
    end
    false
  end

  def search_ignore_context?(context_ids, id)
    unless @options['projects'].include? id.to_i
      return true unless context_ids.has_key? id.to_i
    end
    false
  end

  private

  def build_search_query_a
    if @options["keyword"].blank?
      query = { match_all: {} }
    else
      query = { query_string: { query: @options["keyword"], fields:  %w(title description quote text), default_operator: "AND" } }
    end
    filters = [{terms: { annotation_type: %w(embed comment) } } ]
    filters << {term: { annotated_type: "media"}}
    context_ids = @options["projects"].blank? ? [0] : @options["projects"]
    context_filters = [ {terms: { context_id: context_ids } } ]
    context_filters << {terms: { search_context: context_ids } }
    filter = { bool: { should: [ context_filters ] , must: [ filters ] } }
    get_search_result(query, filter)
  end

  def build_search_query_b
    query = { match_all: {} }
    filters = []
    unless @options["tags"].blank?
      tags = @options["tags"].collect{ |t| t.delete('#') }
      tags.each do |tag|
        filters << { match: { full_tag: { query: tag, operator: 'and' } } }
      end
      filters << { terms: { tag: tags } }
    end
    filter = { bool: { should: filters } }
    filter[:bool][:must] = { terms: { context_id: @options["projects"]} } unless @options["projects"].blank?
    get_search_result(query, filter)
  end

  def build_search_query_c(media_ids)
    query = { match_all: {} }
    filters = [ {term: {annotation_type: "status" } } ]
    filters << { terms: { context_id: @options["projects"]} } unless @options["projects"].blank?
    filter = { bool: { must: [ filters ] } }
    get_search_result(query, filter)
  end

  def build_search_query_recent_activity(media_ids)
    query = { match_all: {} }
    types = ['flag', 'status']
    types << 'tag' if @options['tag'].blank?
    types << 'comment' unless @options["keyword"].blank?
    filters = []
    filters << { terms: { annotation_type: types } }
    filters << { terms: { context_id: @options["projects"]} } unless @options["projects"].blank?
    filter = { bool: { must: [ filters ] } }
    ids = get_search_result(query, filter)
    fetch_media_projects(media_ids, media_ids, ids)
  end

  def get_search_result(query, filter)
    q, g = build_search_query(query, filter)
    ids = {}
    self.get_search_buckets(q, g).each do |result|
      context_ids = {}
      result[:context][:buckets].each do |context|
        if self.should_add_key?(context)
          if context['key'] == 'no_key'
            context[:recent_activity][:hits][:hits][0][:_source][:search_context].each do |sc|
              context_ids[sc.to_i] = context[:recent_activity][:hits][:hits][0][:sort][0] unless self.search_ignore_context?(context_ids, sc)
            end
          else
            context_ids[context['key'].to_i] = context[:recent_activity][:hits][:hits][0][:sort][0] unless self.search_ignore_context?(context_ids, context['key'])
          end
        end
      end
      ids[result['key'].to_i] = context_ids unless context_ids.blank?
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
        terms: { field: :annotated_id, size: 10000 },
        aggs: {
          context: {
            terms: { field: :context_id, missing: :no_key },
              aggs: {
                recent_activity: {
                  top_hits: {
                    sort: [ { created_at: { order: :desc, ignore_unmapped: true } } ],
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
    # Get max timestamp for ProjectMedia accross different arrays.
    ids_p = {}
    ids.each do |k, _v|
      v_a = ids_a[k]
      v_b = ids_b.key?(k) ? ids_b[k] : {}
      ids_p[k] = v_a.keep_if { |kp, _vp| v_b.key? kp }
      ids_p[k].each{|km, _vm| ids_p[k][km] = [v_a[km], v_b[km]].max}
    end
    ids_p
  end

  def check_search_sort(ids)
    ids = prepare_ids_for_sort(ids)
    ids_sort = Array.new
    # sort array based on sort type 'DESC' or 'ASC'
    if @options['sort_type'].upcase == 'DESC'
      ids = ids.sort_by(&:reverse).reverse
    else
      ids = ids.sort_by(&:reverse)
    end
    # load medias wither therir projects
    ids.each do |k, _v|
      p, m = k.split('-')
      media = Media.where(id: m.to_i).last
      unless media.nil?
        media.project_id = p.to_i unless p.blank?
        ids_sort << media
      end
    end
    ids_sort
  end

  def prepare_ids_for_sort(ids)
    # construct an array with key [project-media] and value [timestamp/id]
    result = {}
    ids.each do |m, v|
      v.each do |p, t|
        pm = [p, m].join('-')
        # set value either timestamp or media id based on sort key
        t = m if @options['sort'] == 'recent_added'
        result[pm] = t
      end
    end
    result
  end

end
