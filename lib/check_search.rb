class CheckSearch

  def initialize(options)
    # options include keywords, projects, tags, status
    options = JSON.parse(options)
    @options = options.clone
    @options['input'] = options.clone
    @options['team_id'] = Team.current.id unless Team.current.nil?
    # set sort options
    @options['sort'] = @options['sort'] ||= 'recent_added'
    @options['sort_type'] = @options['sort_type'] ||= 'desc'
  end

  def pusher_channel
    if @options['parent'] && @options['parent']['type'] == 'project'
      Project.find(@options['parent']['id']).pusher_channel
    else
      nil
    end
  end

  def id
    CheckSearch.id(@options['input'])
  end

  def self.id(options = {})
    Base64.encode64("CheckSearch/#{options.to_json}")
  end

  def class_name
    'CheckSearch'
  end

  def medias
    if should_hit_elasticsearch?
      query = medias_build_search_query
      ids = medias_get_search_result(query).map(&:annotated_id)
      items = ProjectMedia.where(id: ids).eager_load(:media)
      sort_es_items(items, ids)
    else
      results = ProjectMedia.eager_load(:media).joins(:project)
      sort_pg_results(results)
    end
  end

  def project_medias
    medias
  end

  def sources
    if should_hit_elasticsearch?
      query = medias_build_search_query('ProjectSource')
      ids = medias_get_search_result(query).map(&:annotated_id)
      items = ProjectSource.where(id: ids).eager_load(:source)
      sort_es_items(items, ids)
    else
      results = ProjectSource.eager_load(:source).joins(:project)
      sort_pg_results(results)
    end
  end

  def project_sources
    sources
  end

  def number_of_results
    # TODO cache `medias` and `sources` results?
    medias.count + sources.count
  end

  private

  def should_hit_elasticsearch?
    !(@options['status'].blank? && @options['tags'].blank? && @options['keyword'].blank?)
  end

  def medias_build_search_query(associated_type = 'ProjectMedia')
    conditions = []
    conditions << {term: { annotated_type: associated_type.downcase } }
    conditions << {term: { team_id: @options["team_id"] } } unless @options["team_id"].nil?
    unless @options["keyword"].blank?
      keyword_c = build_search_keyword_conditions(associated_type)
      conditions << {bool: {should: keyword_c}}
    end
    unless @options["tags"].blank?
      tags_c = []
      tags = @options["tags"].collect{ |t| t.delete('#') }
      tags.each do |tag|
        tags_c << { match: { full_tag: { query: tag, operator: 'and' } } }
      end
      tags_c << { terms: { tag: tags } }
      conditions << {has_child: { type: 'tag_search', query: { bool: {should: tags_c }}}}
    end
    conditions << {terms: { project_id: @options["projects"] } } unless @options["projects"].blank?
    conditions << {terms: { status: @options["status"] } } unless @options["status"].blank?
    { bool: { must: conditions } }
  end

  def build_search_keyword_conditions(associated_type)
    # add keyword conditions
    keyword_fields = %w(title description quote account.username account.title)
    keyword_c = [{ query_string: { query: @options["keyword"], fields: keyword_fields, default_operator: "AND" } }]

    [['comment', 'text'], ['dynamic', 'indexable']].each do |pair|
      keyword_c << { has_child: { type: "#{pair[0]}_search", query: { query_string: { query: @options["keyword"], fields: [pair[1]], default_operator: "AND" }}}}
    end

    if associated_type == 'ProjectSource'
      keyword_c << { has_child: { type: "account_search", query: { query_string: { query: @options["keyword"], fields: %w(username title), default_operator: "AND" }}}}
    end
    keyword_c
  end

  def medias_get_search_result(query)
    field = @options['sort'] == 'recent_activity' ? 'last_activity_at' : 'created_at'
    MediaSearch.search(query: query, sort: [{ field => { order: @options["sort_type"].downcase }}, '_score'], size: 10000).results
  end

  def sort_pg_results(results)
    results = results.where('projects.team_id' => @options['team_id']) unless @options['team_id'].blank?
    results = results.where(project_id: @options['projects']) unless @options['projects'].blank?
    sort_field = @options['sort'].to_s == 'recent_activity' ? 'updated_at' : 'created_at'
    sort_type = @options['sort_type'].blank? ? 'desc' : @options['sort_type'].downcase
    results.order(sort_field => sort_type)
  end

  def sort_es_items(items, ids)
    ids_sort = items.sort_by{|x| ids.index x.id.to_s}
    ids_sort.to_a
  end

end
