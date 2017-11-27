class CheckSearch

  def initialize(options)
    # options include keywords, projects, tags, status
    options = JSON.parse(options)
    @options = options.clone
    @options['input'] = options.clone
    @options['team_id'] = Team.current.id unless Team.current.nil?
    # set sort options
    @options['sort'] ||= 'recent_added'
    @options['sort_type'] ||= 'desc'
    # set show options
    @options['show'] ||= ['medias']
  end

  def pusher_channel
    if @options['parent'] && @options['parent']['type'] == 'project'
      Project.find(@options['parent']['id']).pusher_channel
    elsif @options['parent'] && @options['parent']['type'] == 'team'
      Team.where(slug: @options['parent']['slug']).last.pusher_channel
    else
      nil
    end
  end

  def teams
    []
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
    return [] unless @options['show'].include?('medias')
    return @medias if @medias
    @medias = []
    filters = {}
    filters[:archived] = @options.has_key?('archived') ? (@options['archived'].to_i == 1) : false
    if should_hit_elasticsearch?
      query = medias_build_search_query
      ids = medias_get_search_result(query).map(&:annotated_id)
      items = ProjectMedia.where(filters.merge({ id: ids })).eager_load(:media)
      @medias = sort_es_items(items, ids)
    else
      results = ProjectMedia.where(filters).eager_load(:media).joins(:project)
      @medias = sort_pg_results(results)
    end
    @medias
  end

  def project_medias
    medias
  end

  def sources
    return [] unless @options['show'].include?('sources')
    return @sources if @sources
    @sources = []
    if should_hit_elasticsearch?
      query = medias_build_search_query('TeamSource')
      ids = medias_get_search_result(query).map(&:annotated_id)
      items = TeamSource.where(id: ids).eager_load(:source)
      @sources = sort_es_items(items, ids)
    else
      results = TeamSource.where(team_id: @options['team_id']).eager_load(:source)
      @sources = sort_pg_results(results, 'sources')
    end
    @sources
  end

  def project_sources
    sources
  end

  def number_of_results
    medias.count + sources.count
  end

  private

  def should_hit_elasticsearch?
    !(@options['status'].blank? && @options['tags'].blank? && @options['keyword'].blank?)
  end

  # def show_filter?(type)
  #   # show filter should not include all media types to hit ES
  #   show_options = (type == 'medias') ? ['uploadedimage', 'link', 'claim'] : ['source']
  #   (show_options - @options['show']).empty?
  # end

  def medias_build_search_query(associated_type = 'ProjectMedia')
    conditions = []
    conditions << {term: { annotated_type: associated_type.downcase } }
    conditions << {term: { team_id: @options["team_id"] } } unless @options["team_id"].nil?
    conditions.concat build_search_keyword_conditions(associated_type)
    conditions.concat build_search_tags_conditions
    conditions.concat build_search_parent_conditions(associated_type)
    { bool: { must: conditions } }
  end

  def build_search_keyword_conditions(associated_type)
    return [] if @options["keyword"].blank?
    # add keyword conditions
    keyword_fields = %w(title description quote account.username account.title)
    keyword_c = [{ simple_query_string: { query: @options["keyword"], fields: keyword_fields, default_operator: "AND" } }]

    [['comment', 'text'], ['dynamic', 'indexable']].each do |pair|
      keyword_c << { has_child: { type: "#{pair[0]}_search", query: { simple_query_string: { query: @options["keyword"], fields: [pair[1]], default_operator: "AND" }}}}
    end

    keyword_c << search_tags_query(@options["keyword"].split(' '))

    if associated_type == 'TeamSource'
      keyword_c << { has_child: { type: "account_search", query: { simple_query_string: { query: @options["keyword"], fields: %w(username title), default_operator: "AND" }}}}
    end
    [{ bool: { should: keyword_c } }]
  end

  def build_search_tags_conditions
    return [] if @options["tags"].blank?
    tags_c = search_tags_query(@options["tags"])
    [tags_c]
  end

  def search_tags_query(tags)
    tags_c = []
    tags = tags.collect{ |t| t.delete('#') }
    tags.each do |tag|
      tags_c << { match: { full_tag: { query: tag, operator: 'and' } } }
    end
    tags_c << { terms: { tag: tags } }
    {has_child: { type: 'tag_search', query: { bool: {should: tags_c }}}}
  end

  def build_search_parent_conditions(type)
    parent_c = []

    unless @options['show'].blank?
      types_mapping = {
        'medias' => ['link', 'claim', 'uploadedimage'],
        'sources' => ['source']
      }
      types = @options['show'].collect{ |type| types_mapping[type] }.flatten
      parent_c << { terms: { 'associated_type': types } }
    end

    fields = { 'project_id' => 'projects', 'status' => 'status' }
    fields.each do |k, v|
      parent_c << { terms: { "#{k}": @options[v] } } unless @options[v].blank?
    end
    parent_c
  end

  def medias_get_search_result(query)
    field = @options['sort'] == 'recent_activity' ? 'last_activity_at' : 'created_at'
    MediaSearch.search(query: query, sort: [{ field => { order: @options["sort_type"].downcase }}, '_score'], size: 10000).results
  end

  def sort_pg_results(results, type = 'medias')
    if type == 'medias'
      results = results.where('projects.team_id' => @options['team_id']) unless @options['team_id'].blank?
      results = results.where(project_id: @options['projects']) unless @options['projects'].blank?
    else
      results = results.where('team_id' => @options['team_id']) unless @options['team_id'].blank?
    end
    sort_field = @options['sort'].to_s == 'recent_activity' ? 'updated_at' : 'created_at'
    sort_type = @options['sort_type'].blank? ? 'desc' : @options['sort_type'].downcase
    results.order(sort_field => sort_type)
  end

  def sort_es_items(items, ids)
    ids_sort = items.sort_by{|x| ids.index x.id.to_s}
    ids_sort.to_a
  end

  # def prepare_show_filter(show)
  #   m_types = ['photos', 'links', 'quotes']
  #   show ||= m_types
  #   if show.include?('medias')
  #     show.delete('medias')
  #     show += m_types
  #   end
  #   show.map(&:downcase)
  #   show_mapping = {'photos' => 'uploadedimage', 'links' => 'link', 'quotes' => 'claim', 'sources' => 'source'}
  #   show.each_with_index do |v, i|
  #     show[i] = show_mapping[v] unless show_mapping[v].blank?
  #   end
  #   show
  # end
end
