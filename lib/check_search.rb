class CheckSearch
  include SearchHelper

  def initialize(options, file = nil, team_id = Team.current&.id)
    # Options include search filters
    options = begin JSON.parse(options) rescue {} end
    @options = options.to_h.clone.with_indifferent_access
    @options['input'] = options.clone
    @options['team_id'] = team_condition(team_id)
    @options['operator'] ||= 'AND' # AND or OR

    # Set sort options
    @options['sort'] ||= 'recent_added'
    @options['sort_type'] ||= 'desc'

    # Set show options
    @options['show'] ||= MEDIA_TYPES

    # Set show similar
    @options['show_similar'] ||= false
    @options['eslimit'] ||= 50
    @options['esoffset'] ||= 0
    adjust_es_window_size

    adjust_show_filter
    adjust_channel_filter
    adjust_numeric_range_filter
    adjust_archived_filter
    adjust_language_filter
    adjust_keyword_filter

    # Set es_id option
    @options['es_id'] = Base64.encode64("ProjectMedia/#{@options['id']}") if @options['id'] && ['GraphQL::Types::String', 'GraphQL::Types::Int', 'String', 'Integer'].include?(@options['id'].class.name)

    # Apply feed filters
    @feed_view = @options['feed_view'] || :fact_check
    @options.merge!(@feed.get_feed_filters(@feed_view)) if feed_query?
    @file = file
  end

  MEDIA_TYPES = %w[claims links twitter youtube tiktok instagram facebook telegram weblink images videos audios]
  SORT_MAPPING = {
    'recent_activity' => 'updated_at', 'recent_added' => 'created_at', 'demand' => 'demand',
    'related' => 'linked_items_count', 'last_seen' => 'last_seen', 'share_count' => 'share_count',
    'report_status' => 'report_status', 'tags_as_sentence' => 'tags_as_sentence',
    'media_published_at' => 'media_published_at', 'reaction_count' => 'reaction_count',
    'related_count' => 'related_count', 'suggestions_count' => 'suggestions_count', 'status_index' => 'status_index',
    'type_of_media' => 'type_of_media', 'title' => 'title_index', 'creator_name' => 'creator_name',
    'cluster_size' => 'cluster_size', 'cluster_first_item_at' => 'cluster_first_item_at',
    'cluster_last_item_at' => 'cluster_last_item_at', 'cluster_requests_count' => 'cluster_requests_count',
    'cluster_published_reports_count' => 'cluster_published_reports_count', 'score' => '_score',
    'fact_check_published_on' => 'fact_check_published_on'
  }

  def adjust_keyword_filter
    unless @options['keyword'].blank?
      # This regex removes all characters except letters, numbers, hashtag, search operators, emojis and whitespace
      # in any language - stripping out special characters can improve match results
      @options['keyword'].gsub!(/[^[:word:]\s#'~+\-|()"\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/, ' ')

      # Set fuzzy matching for keyword search, right now with automatic Levenshtein Edit Distance
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
      # https://github.com/elastic/elasticsearch/issues/23366
      @options['keyword'] = "#{@options['keyword']}~" if @options['fuzzy']
    end
  end

  def team_condition(team_id = nil)
    if feed_query?
      feed_teams = @options['feed_team_ids'].is_a?(Array) ? (@feed.team_ids & @options['feed_team_ids']) : @feed.team_ids
      is_shared = FeedTeam.where(feed_id: @feed.id, team_id: Team.current&.id, shared: true).last
      is_shared ? feed_teams : [0] # Invalidate the query if the current team is not sharing content
    else
      [team_id || Team.current&.id].compact.flatten
    end
  end

  def team
    team_id = feed_query? && Team.current ? Team.current.id : @options['team_id'].first
    Team.find_by_id(team_id)
  end

  def feed
    @feed
  end

  def teams
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
    return ProjectMedia.none if @options['team_id'].blank?
    return [] unless !media_types_filter.blank? && index_exists?
    return @medias if @medias
    if should_hit_elasticsearch?
      query = medias_query
      result = medias_get_search_result(query)
      key = get_search_field
      @ids = result.collect{ |i| i[key] }.uniq
      results = ProjectMedia.where(id: @ids).includes(:media)
      @medias = sort_pg_results(results, 'project_medias')
    else
      @medias = get_pg_results
    end
    @medias.where(team_id: @options['team_id'].map(&:to_i)) # Safe check: Be sure that `team_id` filter is always applied
  end

  def project_medias
    medias
  end

  def number_of_results
    number_of_items(medias)
  end

  def number_of_items(collection)
    return collection.size if collection.is_a?(Array)
    if self.should_hit_elasticsearch?
      aggs = {
        total: {
          cardinality: {
            field: self.get_search_field
          }
        }
      }
      response = $repository.search(query: self.medias_query, size: 0, aggs: aggs).raw_response
      return response.dig('aggregations', 'total', 'value')
    end
    collection = collection.unscope(where: :id)
    collection.limit(nil).reorder(nil).offset(nil).count
  end

  def query_all_types?
    MEDIA_TYPES.size == media_types_filter.size
  end

  def should_hit_elasticsearch?
    return true if feed_query?
    status_blank = true
    status_search_fields.each do |field|
      status_blank = false unless @options[field].blank?
    end
    filters_blank = true
    ['tags', 'keyword', 'language', 'fc_language', 'request_language', 'report_language', 'team_tasks', 'assigned_to', 'report_status', 'range_numeric',
      'has_article', 'cluster_teams', 'published_by', 'annotated_by', 'channels', 'cluster_published_reports'
    ].each do |filter|
      filters_blank = false unless @options[filter].blank?
    end
    range_filter = hit_es_for_range_filter
    !(query_all_types? && status_blank && filters_blank && !range_filter && ['recent_activity', 'recent_added', 'last_seen'].include?(@options['sort']))
  end

  def media_types_filter
    [MEDIA_TYPES].flatten & @options['show']
  end

  def get_pg_results
    sort = { SORT_MAPPING[@options['sort'].to_s] => @options['sort_type'].to_s.downcase.to_sym }
    relation = get_pg_results_for_media
    @options['id'] ? relation.where(id: @options['id']) : relation.order(sort).limit(@options['eslimit'].to_i).offset(@options['esoffset'].to_i)
  end

  def item_navigation_offset
    return -1 unless @options['es_id']
    sort_key = SORT_MAPPING[@options['sort'].to_s]
    sort_type = @options['sort_type'].to_s.downcase.to_sym
    pm = ProjectMedia.where(id: @options['id']).last
    return -1 if pm.nil?
    if should_hit_elasticsearch?
      query = medias_query
      conditions = query[:bool][:must]
      es_id = @options['es_id']
      offset_c = item_navigation_offset_condition(sort_type, sort_key)
      conditions << offset_c unless offset_c.nil?
      must_not = [{ ids: { values: [es_id] } }]
      query = { bool: { must: conditions, must_not: must_not } }
      $repository.count(query: query)
    else
      condition = sort_type == :asc ? "project_medias.#{sort_key} < ?" : "project_medias.#{sort_key} > ?"
      get_pg_results_for_media.where(condition, pm.send(sort_key)).count
    end
  end

  def item_navigation_offset_condition(sort_type, sort_key)
    condition = nil
    return condition if sort_key.blank?
    result = $repository.find([@options['es_id']]).first
    unless result.nil?
      sort_value = result[sort_key]
      sort_operator = sort_type == :asc ? :lt : :gt
      condition = { range: { sort_key => { sort_operator => sort_value } } }
    end
    condition
  end

  def self.upload_file(file)
    return nil if file.blank?
    file.rewind
    hash = SecureRandom.hex
    file_path = "check_search/#{hash}"
    CheckS3.write(file_path, file.content_type.gsub(/^video/, 'application'), file.read)
    hash
  end

  def feed_query?
    if @feed.nil?
      @feed = (@options['feed_id'] && Team.current&.is_part_of_feed?(@options['feed_id'])) ? Feed.find(@options['feed_id']) : false
    end
    !!@feed
  end

  def get_pg_results_for_media
    custom_conditions = {}
    core_conditions = {}
    core_conditions['team_id'] = @options['team_id'] if @options['team_id'].is_a?(Array)
    # Add custom conditions for array values
    { 'user_id' => 'users', 'source_id' => 'sources', 'read' => 'read', 'unmatched' => 'unmatched'}.each do |k, v|
      custom_conditions[k] = [@options[v]].flatten if @options.has_key?(v)
    end
    core_conditions.merge!({ archived: @options['archived'] })
    # Use sources_count condition for PG query to get either parent or child based on show_similar option
    core_conditions.merge!({ sources_count: 0 }) unless @options['show_similar']
    range_filter(:pg, custom_conditions)
    relation = ProjectMedia
    if @options['operator'].upcase == 'OR'
      custom_conditions.each do |key, value|
        relation = relation.or(ProjectMedia.where({ key => value }))
      end
    else
      relation = relation.where(custom_conditions)
    end
    if @options['file_type']
      ids = alegre_file_similar_items
      core_conditions.merge!({ 'project_medias.id' => ids })
    end
    relation = relation.distinct('project_medias.id').includes(:media).where(core_conditions)
    relation
  end

  def alegre_file_similar_items
    file_path = "check_search/#{@options['file_handle']}"
    if @file
      hash = CheckSearch.upload_file(@file)
      file_path = "check_search/#{hash}"
    end
    threshold = Bot::Alegre.get_threshold_for_query(@options['file_type'], ProjectMedia.new(team_id: Team.current.id))[0][:value]
    results = Bot::Alegre.get_items_with_similar_media_v2(media_url: CheckS3.public_url(file_path), threshold: [{ value: threshold }], team_ids: @options['team_id'].first, type: @options['file_type'])
    results.blank? ? [0] : results.keys
  end

  def get_search_field
    @options['show_similar'] ? 'annotated_id' : 'parent_id'
  end

  def medias_query
    return build_feed_conditions if feed_query?
    and_conditions, or_conditions, not_conditions = build_es_medias_query
    # Build ES query using this format: `bool: { must: [{and_conditions}], should: [{or_conditions}, must_not: [{not_conditions}]] }`
    query = {}
    { must: and_conditions, should: or_conditions, must_not: not_conditions }.each do |k, v|
      query[k] = v.flatten unless v.blank?
    end
    { bool: query }
  end

  def build_es_medias_query
    core_conditions = []
    custom_conditions = []
    core_conditions << { terms: { get_search_field => @options['project_media_ids'] } } unless @options['project_media_ids'].blank?
    core_conditions << { terms: { team_id: [@options['team_id']].flatten } } if @options['team_id'].is_a?(Array)
    core_conditions << { terms: { archived: @options['archived'] } }
    core_conditions << { term: { sources_count: 0 } } unless @options['show_similar']
    custom_conditions << { terms: { read: @options['read'].map(&:to_i) } } if @options.has_key?('read')
    custom_conditions << { terms: { cluster_teams: @options['cluster_teams'] } } if @options.has_key?('cluster_teams')
    custom_conditions << { terms: { unmatched: @options['unmatched'] } } if @options.has_key?('unmatched')
    custom_conditions.concat keyword_conditions
    custom_conditions.concat tags_conditions
    custom_conditions.concat report_status_conditions
    custom_conditions.concat published_by_conditions
    custom_conditions.concat annotated_by_conditions
    custom_conditions.concat integer_terms_query('assigned_user_ids', 'assigned_to')
    custom_conditions.concat integer_terms_query('channel', 'channels')
    custom_conditions.concat integer_terms_query('source_id', 'sources')
    custom_conditions.concat doc_conditions
    custom_conditions.concat has_article_conditions
    custom_conditions.concat file_filter
    custom_conditions.concat range_filter(:es)
    custom_conditions.concat numeric_range_filter
    custom_conditions.concat language_conditions
    custom_conditions.concat fact_check_language_conditions unless feed_query?
    custom_conditions.concat request_language_conditions
    custom_conditions.concat report_language_conditions
    custom_conditions.concat team_tasks_conditions
    and_conditions = core_conditions
    or_conditions = []
    not_conditions = []
    if @options['operator'].upcase == 'OR'
      or_conditions << custom_conditions
      not_conditions << { term: { associated_type: { value: "Blank" } } }
    else
      and_conditions.concat(custom_conditions)
    end
    return and_conditions, or_conditions, not_conditions
  end

  def medias_get_search_result(query)
    # use collapse to return uniq results
    collapse = { field: get_search_field }
    sort = build_es_sort
    @options['es_id'] ? $repository.find([@options['es_id']]).compact : $repository.search(query: query, collapse: collapse, sort: sort, size: @options['eslimit'], from: @options['esoffset']).results
  end

  def self.get_exported_data(query, team_id)
    team = Team.find(team_id)
    Team.current = team
    search = CheckSearch.new(query, nil, team_id)
    feed_sharing_only_fact_checks = (search.feed && search.feed.data_points == [1])

    # Prepare the export
    data = []
    header = nil
    fields = []
    if feed_sharing_only_fact_checks
      header = ['Fact-check title', 'Fact-check summary', 'Fact-check URL', 'Tags', 'Workspace', 'Updated at', 'Rating']
    else
      header = ['Claim', 'Item page URL', 'Status', 'Created by', 'Submitted at', 'Social Media Posted at', 'Report Published at', 'Number of media', 'Tags']
      fields = team.team_tasks.sort
      fields.each { |tt| header << tt.label }
    end
    data << header

    # Paginate
    search_after = [0]
    while !search_after.empty?
      result = $repository.search(_source: 'annotated_id', query: search.medias_query, sort: [{ annotated_id: { order: :asc } }], size: 10000, search_after: search_after).results
      ids = result.collect{ |i| i['annotated_id'] }.uniq.compact.map(&:to_i)
      pm_report = {}
      Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: ids)
      .find_each do |raw|
        pm_report[raw.annotated_id] = (raw.data['last_published'] || raw.updated_at).to_i if raw.data['state'] == 'published'
      end

      # Iterate through each result and generate an output row for the CSV
      ProjectMedia.where(id: ids, team_id: search.team_condition(team_id)).find_each do |pm|
        row = self.get_exported_data_row(feed_sharing_only_fact_checks, pm, pm_report[pm.id], fields)
        data << row
      end

      search_after = [ids.max].compact
    end

    data
  end

  def self.get_exported_data_row(feed_sharing_only_fact_checks, pm, report_published_at, fields)
    row = nil
    if feed_sharing_only_fact_checks
      row = [
        pm.fact_check_title,
        pm.fact_check_summary,
        pm.fact_check_url,
        pm.tags_as_sentence,
        pm.team_name,
        pm.updated_at_timestamp,
        pm.status
      ]
    else
      report_published_at_value = report_published_at ? Time.at(report_published_at).strftime("%Y-%m-%d %H:%M:%S") : nil
      row = [
        pm.claim_description&.description,
        pm.full_url,
        pm.status_i18n,
        pm.author_name.to_s.gsub(/ \[.*\]$/, ''),
        pm.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        pm.published_at&.strftime("%Y-%m-%d %H:%M:%S"),
        report_published_at_value,
        pm.linked_items_count,
        pm.tags_as_sentence
      ]
      annotations = pm.get_annotations('task').map(&:load)
      fields.each do |field|
        annotation = annotations.find { |a| a.team_task_id == field.id }
        answer = (annotation ? (begin annotation.first_response_obj.file_data[:file_urls].join("\n") rescue annotation.first_response.to_s end) : '')
        answer = begin JSON.parse(answer).collect{ |x| x['url'] }.join(', ') rescue answer end
        row << answer
      end
    end
    row
  end

  private

  def adjust_es_window_size
    window_size = 10000
    current_size = @options['esoffset'].to_i + @options['eslimit'].to_i
    @options['eslimit'] = window_size - @options['esoffset'].to_i if current_size > window_size
  end

  def adjust_channel_filter
    if @options['channels'].is_a?(Array) && @options['channels'].include?('any_tipline')
      channels = @options['channels'] - ['any_tipline']
      @options['channels'] = channels.map(&:to_i).concat(CheckChannels::ChannelCodes::TIPLINE).uniq
    end
  end

  def adjust_show_filter
    if @options['show'].is_a?(Array) && @options['show'].include?('social_media')
      @options['show'].concat(%w[twitter youtube tiktok instagram facebook telegram]).delete('social_media')
      @options['show'].uniq!
    end
  end

  def adjust_numeric_range_filter
    @options['range_numeric'] = {}
    [:linked_items_count, :suggestions_count, :demand, :positive_tipline_search_results_count, :negative_tipline_search_results_count, :tags_as_sentence].each do |field|
      if @options.has_key?(field) && !@options[field].blank?
        @options['range_numeric'][field] = @options[field]
      end
      @options.delete(field)
    end
  end

  def adjust_archived_filter
    @options['archived'] = @options['archived'].blank? ? [CheckArchivedFlags::FlagCodes::NONE, CheckArchivedFlags::FlagCodes::UNCONFIRMED] : [@options['archived']].flatten.map(&:to_i)
  end

  def adjust_language_filter
    unless @options['language_filter'].blank?
      @options['language_filter'].each do |k, v|
        @options[k] = v
      end
      @options.delete('language_filter')
    end
  end

  def index_exists?
    client = $repository.client
    client.indices.exists? index: CheckElasticSearchModel.get_index_alias
  end

  def keyword_conditions
    return [] if @options["keyword"].blank? || @options["keyword"].class.name != 'String'
    set_keyword_fields
    keyword_c = []
    keyword_c.concat build_keyword_conditions_media_fields
    # Search in requests
    [['request_username', 'username'], ['request_identifier', 'identifier'], ['request_content', 'content']].each do |pair|
      keyword_c << {
        nested: {
          path: "requests",
          query: {
            simple_query_string: { query: @options["keyword"], fields: ["requests.#{pair[1]}"], default_operator: "AND" }
          }
        }
      } if should_include_keyword_field?(pair[0])
    end
    # Search in tags
    keyword_c << search_tags_query(@options["keyword"].split(' ')) if should_include_keyword_field?('tags')
    [{ bool: { should: keyword_c } }]
  end

  def set_keyword_fields
    @options['keyword_fields'] ||= {}
    @options['keyword_fields']['fields'] = [] unless @options['keyword_fields'].has_key?('fields')
    # add requests identifier if user check username request field
    @options['keyword_fields']['fields'] << 'request_identifier' if @options['keyword_fields']['fields'].include?('request_username')
  end

  def build_keyword_conditions_media_fields
    es_fields = []
    conditions = []
    %w(title description url claim_description_content fact_check_title fact_check_summary claim_description_context fact_check_url source_name explainer_title).each do |f|
      es_fields << f if should_include_keyword_field?(f)
    end
    es_fields << 'analysis_title' if should_include_keyword_field?('title')
    es_fields.concat(['extracted_text', 'analysis_description']) if should_include_keyword_field?('description')
    conditions << { simple_query_string: { query: @options["keyword"], fields: es_fields, default_operator: "AND" } } unless es_fields.blank?
    conditions
  end

  def should_include_keyword_field?(field)
    @options['keyword_fields']['fields'].blank? || @options['keyword_fields']['fields'].include?(field)
  end

  def language_conditions
    return [] unless @options.has_key?('language')
    [{ terms: { language: @options['language'] } }]
  end

  def fact_check_language_conditions
    return [] unless @options.has_key?('fc_language')
    [{ terms: { fact_check_languages: @options['fc_language'] } }]
  end

  def report_language_conditions
    return [] unless @options.has_key?('report_language')
    [{ terms: { report_language: @options['report_language'] } }]
  end

  def request_language_conditions
    return [] unless @options.has_key?('request_language')
    [{ nested: { path: 'requests', query: { terms: { 'requests.language': @options['request_language'] } } } }]
  end

  def has_article_conditions
    conditions = []
    return conditions unless @options.has_key?('has_article')
    # Build a condidtion with fields that define the item has_article
    has_article_c = []
    ['claim_description_content', 'explainer_title'].each do |field|
      has_article_c << { exists: { field: field } }
    end
    if @options['has_article'].include?('NO_VALUE')
      conditions << { bool: { must_not: has_article_c } }
    elsif @options['has_article'].include?('ANY_VALUE')
      conditions << { bool: { should: has_article_c } }
    end
    conditions
  end

  def file_filter
    conditions = []
    return conditions unless @options.has_key?('file_type')
    ids = alegre_file_similar_items
    [{ terms: { annotated_id: ids } }]
  end

  def team_tasks_conditions
    conditions = []
    return conditions unless @options['team_tasks'].class.name == 'Array'
    @options['team_tasks'].delete_if{ |tt| tt['response'].blank? || tt['id'].blank? }
    @options['team_tasks'].each do |tt|
      must_c = []
      must_c << { term: { "task_responses.team_task_id": tt['id'] } } if tt.has_key?('id')
      response_type = tt['response_type'] ||= 'choice'
      if tt['response'] == 'NO_VALUE'
        conditions << {
          bool: {
            must_not: [
              {
                nested: {
                  path: 'task_responses',
                  query: {
                    bool: {
                      must: [
                        { term: { 'task_responses.team_task_id': tt['id'] } },
                        { exists: { field: 'task_responses.value' } }
                      ]
                    }
                  }
                }
              }
            ]
          }
        }
        next
      elsif %w(ANY_VALUE NUMERIC_RANGE DATE_RANGE).include?(tt['response'])
        method = "format_#{tt['response'].downcase}_team_tasks_field"
        response_condition = self.send(method, tt)
        must_c << response_condition unless response_condition.blank?
      elsif response_type == 'choice'
        must_c << format_choice_team_tasks_field(tt)
      else
        must_c << { match: { "task_responses.value": tt['response'] } }
      end
      conditions << { nested: { path: 'task_responses', query: { bool: { must: must_c } } } }
    end
    conditions
  end

  def build_es_sort
    if SORT_MAPPING.keys.include?(@options['sort'].to_s)
      return [
        { SORT_MAPPING[@options['sort'].to_s] => @options['sort_type'].to_s.downcase.to_sym }
      ]
    end
  end

  def tags_conditions
    return [] if @options["tags"].blank? || @options["tags"].class.name != 'Array'
    tags_c = search_tags_query(@options["tags"])
    [tags_c]
  end

  def integer_terms_query(field, key)
    conditions = []
    return conditions unless @options[key].is_a?(Array)
    # Handle ANY_VALUE or ANY_VALUE
    if @options[key].include?('NO_VALUE')
      conditions << { bool: { must_not: [ { exists: { field: "#{field}" } } ] } }
    elsif @options[key].include?('ANY_VALUE')
      conditions << { exists: { field: "#{field}" } }
    else
      conditions << { terms: { "#{field}": @options[key].map(&:to_i) } }
    end
    conditions
  end

  def search_tags_query(tags)
    tags = tags.collect{ |t| t.delete('#').downcase }
    tags_c = []
    if @options['tags_operator'].to_s.downcase == 'and'
      tags.each do |tag|
        tags_c << { nested: { path: 'tags', query: { match: { 'tags.tag.raw': { query: tag, operator: 'and' } } } } }
      end
      { bool: { must: tags_c } }
    else
      tags.each do |tag|
        tags_c << { match: { "tags.tag.raw": { query: tag, operator: 'and' } } }
      end
      tags_c << { terms: { "tags.tag": tags } }
      { nested: { path: 'tags', query: { bool: { should: tags_c } } } }
    end
  end

  def report_status_conditions
    return [] if @options['report_status'].blank? || !@options['report_status'].is_a?(Array)
    statuses = []
    @options['report_status'].each do |status_name|
      status_id = ['unpublished', 'paused', 'published'].index(status_name) || -1 # Invalidate the query if an invalid status is passed
      statuses << status_id
    end
    [{ terms: { report_status: statuses } }]
  end

  def published_by_conditions
    return [] if @options['published_by'].blank?
    [{ terms: { published_by: [@options['published_by']].flatten } }]
  end

  def annotated_by_conditions
    return [] if @options['annotated_by'].blank?
    if @options['annotated_by_operator'].to_s.downcase == 'and'
      and_c = []
      @options['annotated_by'].each{ |a| and_c << { term: { annotated_by: { value: a } } } }
      [{ bool: { must: and_c }}]
    else
      [{ terms: { annotated_by: [@options['annotated_by']].flatten } }]
    end
  end

  def doc_conditions
    doc_c = []
    unless @options['show'].blank?
      types_mapping = {
        'claims' => ['Claim'],
        'links' => ['facebook', 'instagram', 'tiktok', 'twitter', 'youtube', 'telegram', 'weblink'],
        'facebook' => 'facebook',
        'instagram' => 'instagram',
        'tiktok' => 'tiktok',
        'twitter' => 'twitter',
        'youtube' => 'youtube',
        'telegram' => 'telegram',
        'weblink' => 'weblink',
        'images' => 'UploadedImage',
        'videos' => 'UploadedVideo',
        'audios' => 'UploadedAudio',
      }
      types = @options['show'].collect{ |type| types_mapping[type] }.flatten.uniq.compact
      doc_c << { terms: { 'associated_type': types } }
    end

    fields = { 'user_id' => 'users' }
    status_search_fields.each do |field|
      fields[field] = field
    end
    fields.each do |k, v|
      next unless @options.has_key?(v)
      value = @options[v]
      if value.is_a?(Array) && value.include?(nil)
        doc_c << {
          bool: {
            should: [
              { terms: { k => value.reject{ |v2| v2.nil? } } },
              { bool: { must_not: [{ exists: { field: k } }] } }
            ]
          }
        }
      else
        doc_c << { terms: { k => value } }
      end
    end
    doc_c
  end

  # range: {created_at: {start_time: <start_time>, end_time: <end_time>}, updated_at: {start_time: <start_time>, end_time: <end_time>}, timezone: 'GMT'}
  def range_filter(type, filters = nil)
    conditions = []
    return conditions unless @options.has_key?(:range)
    timezone = @options[:range].delete(:timezone) || @context_timezone
    [:created_at, :updated_at, :last_seen, :media_published_at, :report_published_at].each do |name|
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

  # range_numeric: {field_name: {min: <minimum_number>}, max: <maximum_number> }
  # field_name should be one of the following: linked_items_count, suggestions_count, demand
  def numeric_range_filter
    conditions = []
    return conditions if @options['range_numeric'].blank?
    @options['range_numeric'].each do |field, values|
      range_condition = format_numeric_range_condition(field, values)
      conditions << range_condition unless range_condition.blank?
    end
    conditions
  end

  def format_numeric_range_condition(field, values)
    condition = {}
    return condition if values.nil?
    min, max = values.dig('min'), values.dig('max')
    return condition if min.blank? && max.blank?
    field_condition = {}
    field_condition[:gte] = min.to_i unless min.blank?
    field_condition[:lte] = max.to_i unless max.blank?
    { range: { "#{field}": field_condition } }
  end

  def sort_pg_results(results, table)
    values = []
    @ids.each_with_index do |id, i|
      values << "(#{id}, #{i})"
    end
    return results if values.empty?
    joins = ApplicationRecord.send(:sanitize_sql_array, ["JOIN (VALUES %s) AS x(value, order_number) ON %s.id = x.value", values.join(', '), table])
    results.joins(joins).order('x.order_number')
  end

  def hit_es_for_range_filter
    !@options['range'].blank? && !(['last_seen', 'report_published_at', 'media_published_at'] & @options['range'].keys).blank?
  end

  def build_feed_conditions
    return [] unless feed_query?
    conditions = []
    feed_options = @options.clone
    feed_options.delete('feed_id')
    feed_options.delete('input')
    and_conditions, or_conditions, not_conditions = CheckSearch.new(feed_options.to_json, nil, @options['team_id']).build_es_medias_query
    @feed.get_team_filters(@options['feed_team_ids']).each do |filters|
      team_id = filters['team_id'].to_i
      conditions << CheckSearch.new(filters.merge({ show_similar: !!@options['show_similar'] }).to_json, nil, team_id).medias_query
    end
    or_conditions.concat(conditions)
    query = []
    { must: and_conditions, should: or_conditions, must_not: not_conditions}.each do |k, v|
      query << { bool: { "#{k}": v } } unless v.blank?
    end
    { bool: { must: query } }
  end
end
