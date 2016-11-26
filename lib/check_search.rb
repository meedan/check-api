# :nocov:
class CheckSearch

  def initialize(options, context_team = nil)
    # options include keywords, projects, tags, status
    @options = JSON.parse(options)
    @options['team_id'] = context_team.id
    # set sort options
    @options['sort'] = @options['sort'] ||= 'recent_added'
    @options['sort_type'] = @options['sort_type'] ||= 'DESC'
  end

  def id
    Base64.encode64("CheckSearch/#{@options.to_json}")
  end

  def create
    ids = build_search_query
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

  private

  def build_search_query
    conditions = []
    conditions << {term: { team_id: @options["team_id"] } } unless @options["team_id"].nil?
    unless @options["keyword"].blank?
    conditions << { query_string: { query: @options["keyword"], fields: %w(title description quote text), default_operator: "AND" } }
    end
    conditions << {terms: { project_id: @options["projects"] } } unless @options["projects"].blank?
    conditions << {terms: { status: @options["status"] } } unless @options["status"].blank?
    query = {bool: { must: conditions } }
    get_search_result(query)
  end

  def get_search_result(query)
    field = 'created_at'
    field = 'updated_at' if @options['sort'] == 'recent_activity'
    MediaSearch.search(query: query, sort: [{ field => { order: @options["sort_type"] }}, '_score'], size: 10000).results
  end

end
# :nocov:
