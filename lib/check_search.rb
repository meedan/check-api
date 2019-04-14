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
    @options['eslimit'] ||= 10000
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

  def team
    Team.find(@options['team_id']) unless @options['team_id'].blank?
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

  def get_ids_from_result(results)
    relationship_type = @options['relationship_type']
    results.collect do |result|
      sources = result.relationship_sources || []
      source = relationship_type.blank? ? sources.first : sources.select{ |x| x.split('_').first == Digest::MD5.hexdigest(relationship_type) }.first
      (source.blank? || source == '-') ? result.annotated_id : source.split('_').last.to_i
    end
  end

  def medias
    return [] unless @options['show'].include?('medias') && index_exists?
    return @medias if @medias
    @medias = []
    filters = { inactive: false }
    filters[:archived] = @options.has_key?('archived') ? (@options['archived'].to_i == 1) : false
    filters[:sources_count] = 0
    if should_hit_elasticsearch?
      query = medias_build_search_query
      ids = get_ids_from_result(medias_get_search_result(query))
      filters = filters.merge({ id: ids })
      @ids = ids
    end
    results = ProjectMedia.where(filters).preload(:media).joins(:project)
    @medias = sort_pg_results(results, 'media')
    @medias
  end

  def project_medias
    medias
  end

  def sources
    return [] unless @options['show'].include?('sources') && index_exists?
    return @sources if @sources
    @sources = []
    filters = {}
    if should_hit_elasticsearch?
      query = medias_build_search_query('ProjectSource')
      ids = medias_get_search_result(query).map(&:annotated_id)
      filters = { id: ids }
    end
    results = ProjectSource.where(filters).preload(:source).joins(:project)
    @sources = sort_pg_results(results, 'source')
    @sources
  end

  def project_sources
    sources
  end

  def number_of_results
    medias_count = medias.is_a?(Array) ? medias.size : medias.permissioned.count
    sources_count = sources.is_a?(Array) ? sources.size : sources.permissioned.count
    medias_count + sources_count
  end

  def medias_build_search_query(associated_type = 'ProjectMedia')
    conditions = []
    conditions << {term: { annotated_type: associated_type.downcase } }
    conditions << {term: { team_id: @options["team_id"] } } unless @options["team_id"].nil?
    conditions.concat build_search_keyword_conditions
    conditions.concat build_search_tags_conditions
    conditions.concat build_search_doc_conditions
    dynamic_conditions = build_search_dynamic_annotation_conditions
    conditions.concat(dynamic_conditions) unless dynamic_conditions.blank?
    { bool: { must: conditions } }
  end

  def medias_get_search_result(query)
    sort = build_search_dynamic_annotation_sort
    MediaSearch.search(query: query, sort: sort, size: @options['eslimit']).results
  end

  private

  def index_exists?
    client = MediaSearch.gateway.client
    client.indices.exists? index: CheckElasticSearchModel.get_index_alias
  end

  def should_hit_elasticsearch?
    status_blank = true
    status_search_fields.each do |field|
      status_blank = false unless @options[field].blank?
    end
    !(status_blank && @options['tags'].blank? && @options['keyword'].blank? && @options['dynamic'].blank? && ['recent_activity', 'recent_added'].include?(@options['sort']))
  end

  # def show_filter?(type)
  #   # show filter should not include all media types to hit ES
  #   show_options = (type == 'medias') ? ['uploadedimage', 'link', 'claim'] : ['source']
  #   (show_options - @options['show']).empty?
  # end

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
        condition = Dynamic.send(method, values)
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

  def build_search_dynamic_annotation_sort
    return [] if ['recent_activity', 'recent_added'].include?(@options['sort'].to_s)
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
        'medias' => ['Link', 'Claim', 'UploadedImage'],
        'sources' => ['Source']
      }
      types = @options['show'].collect{ |type| types_mapping[type] }.flatten
      doc_c << { terms: { 'associated_type': types } }
    end

    fields = { 'project_id' => 'projects' }
    status_search_fields.each do |field|
      fields[field] = field
    end
    fields.each do |k, v|
      doc_c << { terms: { "#{k}": @options[v] } } unless @options[v].blank?
    end
    doc_c
  end

  def filter_by_team_and_project(results)
    results = results.where('projects.team_id' => @options['team_id']) unless @options['team_id'].blank?
    results = results.where(project_id: @options['projects']) unless @options['projects'].blank?
    results
  end

  def get_order
    sort_field = @options['sort'].to_s == 'recent_activity' ? 'updated_at' : 'created_at'
    sort_type = @options['sort_type'].blank? ? 'desc' : @options['sort_type'].downcase
    { sort_field => sort_type }
  end

  def sort_pg_results(results, type)
    results = filter_by_team_and_project(results)

    if ['recent_activity', 'recent_added'].include?(@options['sort'].to_s)
      results = results.order(get_order)
    elsif @ids && type == 'media'
      values = []
      @ids.each_with_index do |id, i|
        values << "(#{id}, #{i})"
      end
      return results if values.empty?
      joins = ActiveRecord::Base.send(:sanitize_sql_array, ["JOIN (VALUES %s) AS x(value, order_number) ON project_medias.id = x.value", values.join(', ')])
      results = results.joins(joins).order('x.order_number')
    end

    results
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
