class CheckSearch
  def initialize(options)
    # options include keywords, projects, tags, status
    options = JSON.parse(options)
    @options = options.clone.with_indifferent_access
    @options['input'] = options.clone
    @options['team_id'] = Team.current.id unless Team.current.nil?
    # set sort options
    @options['sort'] ||= 'recent_activity'
    @options['sort_type'] ||= 'desc'
    # set show options
    @options['show'] ||= MEDIA_TYPES
    @options['eslimit'] ||= 20
    @options['esoffset'] ||= 0
    Project.current = Project.where(id: @options['projects'].last).last if @options['projects'].to_a.size == 1 && Project.current.nil?
  end

  MEDIA_TYPES = %w[claims links images videos audios blank]
  SORT_MAPPING = {
    'recent_activity' => 'updated_at', 'recent_added' => 'created_at', 'demand' => 'demand',
    'related' => 'linked_items_count', 'last_seen' => 'last_seen', 'share_count' => 'share_count'
  }

  def pusher_channel
    if @options['parent'] && @options['parent']['type'] == 'project'
      Project.find(@options['parent']['id']).pusher_channel
    elsif @options['parent'] && @options['parent']['type'] == 'team'
      Team.where(slug: @options['parent']['slug']).last.pusher_channel
    else
      nil
    end
  end

  def team
    Team.find(@options['team_id']) unless @options['team_id'].blank?
  end

  def teams
    []
  end

  def projects
    []
  end

  def id
    CheckSearch.id(@options['input'])
  end

  def self.id(options = {})
    Base64.strict_encode64("CheckSearch/#{options.to_json}")
  end

  def class_name
    'CheckSearch'
  end

  def medias
    return [] unless !media_types_filter.blank? && index_exists?
    return @medias if @medias
    if should_hit_elasticsearch?('ProjectMedia')
      query = medias_build_search_query
      @ids = medias_get_search_result(query).map(&:annotated_id).uniq
      results = ProjectMedia.where(id: @ids)
      @medias = sort_pg_results(results, 'project_medias')
    else
      @medias = get_pg_results
    end
    @medias
  end

  def project_medias
    medias
  end

  def number_of_results
    number_of_items(medias, 'ProjectMedia')
  end

  def number_of_items(collection, associated_type)
    return collection.size if collection.is_a?(Array)
    return MediaSearch.gateway.client.count(index: CheckElasticSearchModel.get_index_alias, body: { query: medias_build_search_query(associated_type) })['count'].to_i if self.should_hit_elasticsearch?(associated_type)
    user = User.current
    collection = collection.unscope(where: :id)
    collection = collection.where(id: user.cached_assignments[:pmids]) if associated_type == 'ProjectMedia' && user && user.role?(:annotator)
    collection.limit(nil).reorder(nil).offset(nil).count
  end

  def should_hit_elasticsearch?(associated_type)
    status_blank = true
    status_search_fields.each do |field|
      status_blank = false unless @options[field].blank?
    end
    query_all_types = true
    if associated_type == 'ProjectMedia'
      query_all_types = (MEDIA_TYPES.size == media_types_filter.size)
    end
    filters_blank = true
    ['tags', 'keyword', 'rules', 'dynamic'].each do |filter|
      filters_blank = false unless @options[filter].blank?
    end
    !(query_all_types && status_blank && filters_blank && ['recent_activity', 'recent_added'].include?(@options['sort']))
  end

  def media_types_filter
    MEDIA_TYPES & @options['show']
  end

  def get_pg_results
    sort = { SORT_MAPPING[@options['sort'].to_s] => @options['sort_type'].to_s.downcase.to_sym }
    relation = get_pg_results_for_media
    @options['id'] ? relation.where(id: @options['id']) : relation.order(sort).limit(@options['eslimit'].to_i).offset(@options['esoffset'].to_i)
  end

  def item_navigation_offset
    return -1 unless @options['id']
    sort_key = SORT_MAPPING[@options['sort'].to_s]
    sort_type = @options['sort_type'].to_s.downcase.to_sym
    pm = ProjectMedia.where(id: @options['id']).last
    return -1 if pm.nil?
    if should_hit_elasticsearch?('ProjectMedia')
      query = medias_build_search_query('ProjectMedia')
      conditions = query[:bool][:must]
      es_id = Base64.encode64("ProjectMedia/#{@options['id']}")
      sort_value = MediaSearch.find(es_id).send(sort_key)
      sort_operator = sort_type == :asc ? :lt : :gt
      conditions << { range: { sort_key => { sort_operator => sort_value } } }
      must_not = [{ ids: { values: [es_id] } }]
      query = { bool: { must: conditions, must_not: must_not } }
      MediaSearch.gateway.client.count(index: CheckElasticSearchModel.get_index_alias, body: { query: query })['count'].to_i
    else
      condition = sort_type == :asc ? "#{sort_key} < ?" : "#{sort_key} > ?"
      get_pg_results_for_media.where(condition, pm.send(sort_key)).count
    end
  end

  def get_pg_results_for_media
    filters = {}
    filters['team_id'] = @options['team_id'] unless @options['team_id'].blank?
    filters['project_media_projects.project_id'] = [@options['projects']].flatten unless @options['projects'].blank?
    filters['user_id'] = [@options['users']].flatten unless @options['users'].blank?
    filters['read'] = @options['read'].to_i if @options.has_key?('read')
    archived = @options.has_key?('archived') ? (@options['archived'].to_i == 1) : false
    filters = filters.merge({
      archived: archived,
      sources_count: 0
    })
    build_search_range_filter(:pg, filters)
    relation = ProjectMedia.where(filters).distinct('project_medias.id').includes(:media)
    relation = relation.joins(:project_media_projects) unless @options['projects'].blank?
    relation
  end

  def medias_build_search_query(associated_type = 'ProjectMedia')
    conditions = []
    conditions << { term: { annotated_type: associated_type.downcase } }
    conditions << { term: { team_id: @options['team_id'] } } unless @options['team_id'].nil?
    if associated_type == 'ProjectMedia'
      archived = @options['archived'].to_i
      conditions << { term: { archived: archived } }
      conditions << { term: { read: @options['read'].to_i } } if @options.has_key?('read')
      conditions << { term: { sources_count: 0 } } unless @options['include_related_items']
      user = User.current
      conditions << { terms: { annotated_id: user.cached_assignments[:pmids] } } if user&.role?(:annotator)
      conditions.concat build_search_range_filter(:es)
    end
    conditions.concat build_search_keyword_conditions
    conditions.concat build_search_tags_conditions
    conditions.concat build_search_doc_conditions
    conditions.concat build_search_range_filter(:es)
    dynamic_conditions = build_search_dynamic_annotation_conditions
    conditions.concat(dynamic_conditions) unless dynamic_conditions.blank?
    rules_conditions = build_search_rules_conditions
    conditions.concat(rules_conditions) unless rules_conditions.blank?
    { bool: { must: conditions } }
  end

  def medias_get_search_result(query)
    sort = build_search_sort
    @options['id'] ? [MediaSearch.find(Base64.encode64("ProjectMedia/#{@options['id']}"))] : MediaSearch.search(query: query, sort: sort, size: @options['eslimit'], from: @options['esoffset']).results
  end

  private

  def index_exists?
    client = MediaSearch.gateway.client
    client.indices.exists? index: CheckElasticSearchModel.get_index_alias
  end

  def build_search_keyword_conditions
    return [] if @options["keyword"].blank?
    # add keyword conditions
    keyword_fields = %w(title description quote)
    keyword_c = [{ simple_query_string: { query: @options["keyword"], fields: keyword_fields, default_operator: "AND" } }]

    [['comments', 'text'], ['dynamics', 'indexable']].each do |pair|
      keyword_c << { nested: { path: "#{pair[0]}", query: { simple_query_string: { query: @options["keyword"], fields: ["#{pair[0]}.#{pair[1]}"], default_operator: "AND" }}}}
    end

    keyword_c << search_tags_query(@options["keyword"].split(' '))

    keyword_c << { nested: { path: "accounts", query: { simple_query_string: { query: @options["keyword"], fields: %w(accounts.username accounts.title), default_operator: "AND" }}}}

    [{ bool: { should: keyword_c } }]
  end

  def build_search_dynamic_annotation_conditions
    conditions = []
    return conditions unless @options.has_key?('dynamic')
    @options['dynamic'].each do |name, values|
      next if values.blank?
      method = "field_search_query_type_#{name}"
      condition = nil
      if Dynamic.respond_to?(method)
        condition = Dynamic.send(method, values, @options['dynamic'])
      # To be enabled for other dynamic filters
      # else
      #   queries = []
      #   values.each do |value|
      #     query = { term: { "dynamics.#{name}": value } }
      #     queries << query
      #   end
      #   condition = {
      #     nested: {
      #       path: 'dynamics',
      #       query: {
      #         bool: {
      #           should: queries
      #         }
      #       }
      #     }
      #   }
      end
      conditions << condition unless condition.nil?
    end
    conditions
  end

  def build_search_rules_conditions
    conditions = []
    return conditions unless @options.has_key?('rules')
    @options['rules'].each do |rule|
      conditions << { term: { rules: rule } }
    end
    [{ bool: { should: conditions } }]
  end

  def build_search_sort
    if SORT_MAPPING.keys.include?(@options['sort'].to_s)
      return [
        { SORT_MAPPING[@options['sort'].to_s] => @options['sort_type'].to_s.downcase.to_sym }
      ]
    end
    [
      {
        "dynamics.#{@options['sort']}": {
          order: @options['sort_type'],
          unmapped_type: 'long',
          nested: {
            path: 'dynamics'
          }
        }
      }
    ]
  end

  def build_search_tags_conditions
    return [] if @options["tags"].blank?
    tags_c = search_tags_query(@options["tags"])
    [tags_c]
  end

  def search_tags_query(tags)
    tags_c = []
    tags = tags.collect{ |t| t.delete('#').downcase }
    tags.each do |tag|
      tags_c << { match: { "tags.tag.raw": { query: tag, operator: 'and' } } }
    end
    tags_c << { terms: { "tags.tag": tags } }
    { nested: { path: 'tags', query: { bool: { should: tags_c } } } }
  end

  def build_search_doc_conditions
    doc_c = []

    unless @options['show'].blank?
      types_mapping = {
        'claims' => ['Claim'],
        'links' => 'Link',
        'images' => 'UploadedImage',
        'videos' => 'UploadedVideo',
        'audios' => 'UploadedAudio',
        'blank' => 'Blank',
      }
      types = @options['show'].collect{ |type| types_mapping[type] }.flatten
      doc_c << { terms: { 'associated_type': types } }
    end

    fields = { 'project_id' => 'projects', 'user_id' => 'users' }
    status_search_fields.each do |field|
      fields[field] = field
    end
    fields.each do |k, v|
      doc_c << { terms: { "#{k}": @options[v] } } if @options.has_key?(v)
    end
    doc_c
  end

  def format_time_with_timezone(time, tz)
    begin
      Time.use_zone(tz) { Time.zone.parse(time) }
    rescue StandardError
      nil
    end
  end

  def format_times_search_range_filter(values, timezone)
    return if values.blank?
    tz = (!timezone.blank? && ActiveSupport::TimeZone[timezone]) ? timezone : 'UTC'
    from = format_time_with_timezone(values.dig('start_time'), tz)
    to = format_time_with_timezone(values.dig('end_time'), tz)
    return if from.blank? && to.blank?
    from ||= DateTime.new
    to ||= DateTime.now.in_time_zone(tz)
    to = to.end_of_day if to.strftime('%T') == '00:00:00'
    [from, to]
  end

  # range: {created_at: {start_time: <start_time>, end_time: <end_time>}, updated_at: {start_time: <start_time>, end_time: <end_time>}, timezone: 'GMT'}
  def build_search_range_filter(type, filters = nil)
    conditions = []
    return conditions unless @options.has_key?(:range)
    timezone = @options[:range].delete(:timezone) || @context_timezone
    [:created_at, :updated_at].each do |name|
      values = @options['range'].dig(name)
      range = format_times_search_range_filter(values, timezone)
      next if range.nil?
      if type == :pg
        filters[name] = range[0]..range[1]
      else
        method = "field_search_query_type_range_#{name}"
        conditions << ProjectMedia.send(method, range, timezone)
      end
    end
    conditions
  end

  def sort_pg_results(results, table)
    values = []
    @ids.each_with_index do |id, i|
      values << "(#{id}, #{i})"
    end
    return results if values.empty?
    joins = ActiveRecord::Base.send(:sanitize_sql_array, ["JOIN (VALUES %s) AS x(value, order_number) ON %s.id = x.value", values.join(', '), table])
    results.joins(joins).order('x.order_number')
  end
end
