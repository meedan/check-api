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

  def create
    query = build_search_query
    get_search_result(query)
  end

  def search_result
    if self.should_hit_elasticsearch?
      self.create
    else
      self.from_relational_db
    end
  end

  def should_hit_elasticsearch?
    !(@options['status'].blank? && @options['tags'].blank? && @options['keyword'].blank?)
  end

  def from_relational_db
    results = ProjectMedia.joins(:project)
    results = results.where('projects.team_id' => @options['team_id']) unless @options['team_id'].blank?
    results = results.where(project_id: @options['projects']) unless @options['projects'].blank?
    sort_field = @options['sort'].to_s == 'recent_activity' ? 'updated_at' : 'created_at'
    sort_type = @options['sort_type'].blank? ? 'desc' : @options['sort_type'].downcase
    results.order(sort_field => sort_type)
  end

  def medias
    if self.should_hit_elasticsearch?
      # should loop in search result and return media
      # for now all results are medias
      ids = self.search_result.map(&:id)
      items = ProjectMedia.where(id: ids)
      ids_sort = items.sort_by{|x| ids.index x.id.to_s}
      ids_sort.to_a
    else
      self.from_relational_db
    end
  end

  def project_medias
    self.medias
  end

  def number_of_results
    self.search_result.count
  end

  private

  def build_search_query
    conditions = []
    conditions << {term: { team_id: @options["team_id"] } } unless @options["team_id"].nil?
    unless @options["keyword"].blank?
      # add keyword conditions
      keyword_c = [{ query_string: { query: @options["keyword"], fields: %w(title description quote), default_operator: "AND" } }]
      
      [['comment', 'text'], ['dynamic', 'indexable']].each do |pair|
        keyword_c << { has_child: { type: "#{pair[0]}_search", query: { query_string: { query: @options["keyword"], fields: [pair[1]], default_operator: "AND" }}}}
      end
      
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

  def get_search_result(query)
    field = 'created_at'
    field = 'last_activity_at' if @options['sort'] == 'recent_activity'
    MediaSearch.search(query: query, sort: [{ field => { order: @options["sort_type"].downcase }}, '_score'], size: 10000).results
  end

end
