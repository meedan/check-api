class CheckSearch
  def initialize(options, file = nil, team_id = nil)
    # options include keywords, projects, tags, status, report status
    options = begin JSON.parse(options) rescue {} end
    @options = options.clone.with_indifferent_access
    @options['input'] = options.clone
    @options['team_id'] = team_condition(team_id)
    @options['operator'] ||= 'AND' # AND or OR
    # set sort options
    smooch_bot_installed = TeamBotInstallation.where(team_id: @options['team_id'], user_id: BotUser.smooch_user&.id).exists?
    @options['sort'] ||= (smooch_bot_installed ? 'last_seen' : 'recent_added')
    @options['sort_type'] ||= 'desc'
    # set show options
    @options['show'] ||= MEDIA_TYPES
    # set show similar
    @options['show_similar'] ||= false
    @options['eslimit'] ||= 50
    @options['esoffset'] ||= 0
    adjust_es_window_size
    # Check for non project
    @options['none_project'] = @options['projects'].include?('-1') unless @options['projects'].blank?
    adjust_project_filter
    adjust_channel_filter
    adjust_numeric_range_filter
    # set es_id option
    @options['es_id'] = Base64.encode64("ProjectMedia/#{@options['id']}") if @options['id'] && ['String', 'Integer'].include?(@options['id'].class.name)
    Project.current = Project.where(id: @options['projects'].last).last if @options['projects'].to_a.size == 1 && Project.current.nil?
    @file = file
  end

  MEDIA_TYPES = %w[claims links images videos audios blank]
  SORT_MAPPING = {
    'recent_activity' => 'updated_at', 'recent_added' => 'created_at', 'demand' => 'demand',
    'related' => 'linked_items_count', 'last_seen' => 'last_seen', 'share_count' => 'share_count',
    'published_at' => 'published_at', 'report_status' => 'report_status', 'tags_as_sentence' => 'tags_as_sentence',
    'media_published_at' => 'media_published_at', 'reaction_count' => 'reaction_count', 'comment_count' => 'comment_count',
    'related_count' => 'related_count', 'suggestions_count' => 'suggestions_count', 'status_index' => 'status_index',
    'type_of_media' => 'type_of_media', 'title' => 'sort_title', 'creator_name' => 'creator_name'
  }

  def team_condition(team_id = nil)
    return team_id unless team_id.nil?
    if @options['country'] && User.current&.is_admin?
      country = [@options['country']].flatten.reject{ |c| c.blank? }
      Team.where(country: country).map(&:id)
    else
      Team.current&.id
    end
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
    team_id = @options['team_id'].is_a?(Array) ? @options['team_id'].first : @options['team_id']
    Team.find(team_id) unless team_id.blank?
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
    if should_hit_elasticsearch?
      query = medias_build_search_query
      result = medias_get_search_result(query)
      key = get_search_field
      @ids = result.collect{ |i| i[key] }.uniq
      results = ProjectMedia.where(id: @ids).includes(:media).includes(:project)
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
    number_of_items(medias)
  end

  def number_of_items(collection)
    return collection.size if collection.is_a?(Array)
    return $repository.client.count(index: CheckElasticSearchModel.get_index_alias, body: { query: medias_build_search_query })['count'].to_i if self.should_hit_elasticsearch?
    collection = collection.unscope(where: :id)
    collection.limit(nil).reorder(nil).offset(nil).count
  end

  def should_hit_elasticsearch?
    status_blank = true
    status_search_fields.each do |field|
      status_blank = false unless @options[field].blank?
    end
    query_all_types = (MEDIA_TYPES.size == media_types_filter.size)
    filters_blank = true
    ['tags', 'keyword', 'rules', 'dynamic', 'team_tasks', 'assigned_to', 'report_status', 'range_numeric'].each do |filter|
      filters_blank = false unless @options[filter].blank?
    end
    range_filter = hit_es_for_range_filter
    !(query_all_types && status_blank && filters_blank && !range_filter && ['recent_activity', 'recent_added', 'last_seen'].include?(@options['sort']))
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
    return -1 unless @options['es_id']
    sort_key = SORT_MAPPING[@options['sort'].to_s]
    sort_type = @options['sort_type'].to_s.downcase.to_sym
    pm = ProjectMedia.where(id: @options['id']).last
    return -1 if pm.nil?
    if should_hit_elasticsearch?
      query = medias_build_search_query
      conditions = query[:bool][:must]
      es_id = @options['es_id']
      offset_c = item_navigation_offset_condition(sort_type, sort_key)
      conditions << offset_c unless offset_c.nil?
      must_not = [{ ids: { values: [es_id] } }]
      query = { bool: { must: conditions, must_not: must_not } }
      $repository.count(query: query)
    else
      condition = sort_type == :asc ? "#{sort_key} < ?" : "#{sort_key} > ?"
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

  def get_pg_results_for_media
    custom_conditions = {}
    core_conditions = {}
    core_conditions['team_id'] = @options['team_id'] unless @options['team_id'].blank?
    # Add custom conditions for array values
    {
      'project_id' => 'projects', 'user_id' => 'users', 'source_id' => 'sources', 'channel' => 'channels', 'read' => 'read'
    }.each do |k, v|
      custom_conditions[k] = [@options[v]].flatten if @options.has_key?(v)
    end
    archived = @options['archived'].to_i
    core_conditions.merge!({ archived: archived })
    core_conditions.merge!({ sources_count: 0 }) unless should_include_related_items?
    build_search_range_filter(:pg, custom_conditions)
    relation = ProjectMedia
    if @options['operator'].upcase == 'OR'
      custom_conditions.each do |key, value|
        relation = relation.or(ProjectMedia.where({ key => value }))
      end
    else
      relation = relation.where(custom_conditions)
    end
    if @options['file_type']
      file_path = "check_search/#{@options['file_handle']}"
      if @file
        hash = CheckSearch.upload_file(@file)
        file_path = "check_search/#{hash}"
      end
      threshold = Bot::Alegre.get_threshold_for_query(@options['file_type'], ProjectMedia.new(team_id: Team.current&.id))[:value]
      results = Bot::Alegre.get_items_with_similar_media(CheckS3.public_url(file_path), { value: threshold }, @options['team_id'], "/#{@options['file_type']}/similarity/")
      ids = results.blank? ? [0] : results.keys
      core_conditions.merge!({ 'project_medias.id' => ids })
    end
    relation.distinct('project_medias.id').includes(:media).includes(:project).where(core_conditions)
  end

  def should_include_related_items?
    @options['show_similar'] || show_parent?
  end

  def show_parent?
    search_keys = ['verification_status', 'tags', 'rules', 'dynamic', 'team_tasks', 'assigned_to', 'channels', 'report_status']
    !@options['projects'].blank? && !@options['keyword'].blank? && (search_keys & @options.keys).blank?
  end

  def get_search_field
    field = 'annotated_id'
    field = 'parent_id' if !@options['show_similar'] && show_parent?
    field
  end

  def medias_build_search_query
    core_conditions = []
    custom_conditions = []
    core_conditions << { terms: { team_id: [@options['team_id']].flatten } } unless @options['team_id'].blank?
    archived = @options['archived'].to_i
    core_conditions << { term: { archived: archived } }
    custom_conditions << { terms: { read: @options['read'].map(&:to_i) } } if @options.has_key?('read')
    core_conditions << { term: { sources_count: 0 } } unless should_include_related_items?
    custom_conditions.concat build_search_keyword_conditions
    custom_conditions.concat build_search_tags_conditions
    custom_conditions.concat build_search_report_status_conditions
    custom_conditions.concat build_search_integer_terms_query('assigned_user_ids', 'assigned_to')
    custom_conditions.concat build_search_integer_terms_query('channel', 'channels')
    custom_conditions.concat build_search_integer_terms_query('source_id', 'sources')
    custom_conditions.concat build_search_doc_conditions
    custom_conditions.concat build_search_range_filter(:es)
    custom_conditions.concat build_search_numeric_range_filter
    dynamic_conditions = build_search_dynamic_annotation_conditions
    check_search_concat_conditions(custom_conditions, dynamic_conditions)
    team_tasks_conditions = build_search_team_tasks_conditions
    check_search_concat_conditions(custom_conditions, team_tasks_conditions)
    if @options['operator'].upcase == 'OR'
      and_conditions = { bool: { must: core_conditions } }
      or_conditions = { bool: { should: custom_conditions } }
      { bool: { must: [and_conditions, or_conditions] } }
    else
      { bool: { must: core_conditions + custom_conditions } }
    end
  end

  def check_search_concat_conditions(base_condition, c)
    base_condition.concat(c) unless c.blank?
  end

  def medias_get_search_result(query)
    # use collapse to return uniq results
    collapse = { field: get_search_field }
    sort = build_search_sort
    @options['es_id'] ? $repository.find([@options['es_id']]).compact : $repository.search(query: query, collapse: collapse, sort: sort, size: @options['eslimit'], from: @options['esoffset']).results
  end

  private

  def adjust_es_window_size
    window_size = 10000
    current_size = @options['esoffset'].to_i + @options['eslimit'].to_i
    @options['eslimit'] = window_size - @options['esoffset'].to_i if  current_size > window_size
  end

  def adjust_project_filter
    project_group_ids = [@options['project_group_id']].flatten.reject{ |pgid| pgid.blank? }.map(&:to_i)
    unless project_group_ids.empty?
      project_ids = @options['projects'].to_a.map(&:to_i)
      project_groups_project_ids = Project.where(project_group_id: project_group_ids, team: @options['team_id']).map(&:id)

      project_ids = project_ids.blank? ? project_groups_project_ids : (project_ids & project_groups_project_ids)

      # Invalidate the search if empty... otherwise, adjust the projects filter
      @options['projects'] = project_ids.empty? ? [0] : project_ids
    end
    # Also, adjust projects filter taking projects' privacy settings into account
    if Team.current && !@options['country']
      @options['projects'] = @options['projects'].blank? ? (Project.where(team_id: Team.current.id).allowed(Team.current).map(&:id) + [nil]) : Project.where(id: @options['projects']).allowed(Team.current).map(&:id)
    end
    @options['projects'] += [nil] if @options['none_project']
  end

  def adjust_channel_filter
    if @options['channels'].is_a?(Array) && @options['channels'].include?('any_tipline')
      channels = @options['channels'] - ['any_tipline']
      @options['channels'] = channels.map(&:to_i).concat(CheckChannels::ChannelCodes::TIPLINE).uniq
    end
  end

  def adjust_numeric_range_filter
    @options['range_numeric'] = {}
    [:linked_items_count, :suggestions_count, :demand].each do |field|
      if @options.has_key?(field) && !@options[field].blank?
        @options['range_numeric'][field] = @options[field]
      end
      @options.delete(field)
    end
  end

  def index_exists?
    client = $repository.client
    client.indices.exists? index: CheckElasticSearchModel.get_index_alias
  end

  def build_search_keyword_conditions
    return [] if @options["keyword"].blank? || @options["keyword"].class.name != 'String'
    if Team.current&.get_trends_enabled && @options["keyword"].split(/\s+/).size > 3
      result = Bot::Alegre.get_similar_texts([@options['team_id']].flatten, @options["keyword"])
      pmids = result.empty? ? [0] : result.keys
      return [{ bool: { must: [{ terms: { parent_id: pmids }}] }}]
    end
    set_keyword_fields
    keyword_c = []
    field_conditions = build_keyword_conditions_media_fields
    check_search_concat_conditions(keyword_c, field_conditions)
    [['comments', 'text'], ['task_comments', 'text'], ['dynamics', 'indexable']].each do |pair|
      keyword_c << {
        nested: {
          path: "#{pair[0]}",
          query: {
            simple_query_string: { query: @options["keyword"], fields: ["#{pair[0]}.#{pair[1]}"], default_operator: "AND" }
          }
        }
      } if should_include_keyword_field?(pair[0])
    end

    keyword_c << search_tags_query(@options["keyword"].split(' ')) if should_include_keyword_field?('tags')

    keyword_c << {
      nested: {
        path: "accounts",
        query: { simple_query_string: { query: @options["keyword"], fields: %w(accounts.username accounts.title), default_operator: "AND" }}
      }
    } if should_include_keyword_field?('accounts')

    team_tasks_c = build_keyword_conditions_team_tasks
    check_search_concat_conditions(keyword_c, team_tasks_c)

    [{ bool: { should: keyword_c } }]
  end

  def set_keyword_fields
    @options['keyword_fields'] ||= {}
    @options['keyword_fields']['fields'] = [] unless @options['keyword_fields'].has_key?('fields')
    @options['keyword_fields']['fields'] << 'team_tasks' if @options['keyword_fields'].has_key?('team_tasks')
  end

  def build_keyword_conditions_media_fields
    es_fields = []
    conditions = []
    %w(title description quote analysis_title analysis_description url extracted_text).each do |f|
      es_fields << f if should_include_keyword_field?(f)
    end
    conditions << { simple_query_string: { query: @options["keyword"], fields: es_fields, default_operator: "AND" } } unless es_fields.blank?
    conditions
  end

  def build_keyword_conditions_team_tasks
    conditions = []
    # add tasks/metadata answers
    {'task_answers' => 'tasks', 'metadata_answers' => 'metadata'}.each do |f, v|
      conditions << {
        nested: {
          path: "task_responses",
          query: { bool: { must: [
              { simple_query_string: { query: @options["keyword"], fields: ["task_responses.value"], default_operator: "AND" } },
              { term: { "task_responses.fieldset": { value: v } } }
            ]
          } }
        }
      } if should_include_keyword_field?(f)
    end
    # add team task/metadata filter (ids)
    # should search in responses and comments
    if should_include_keyword_field?('team_tasks') && !@options['keyword_fields']['team_tasks'].blank?
      [['task_responses', 'value'], ['task_comments', 'text']].each do |pair|
        conditions << {
          nested: {
            path: pair[0],
            query: { bool: { must: [
                { terms: { "#{pair[0]}.team_task_id": @options['keyword_fields']['team_tasks'] } },
                { match: { "#{pair[0]}.#{pair[1]}": @options["keyword"] } }
              ]
            } }
          }
        }
      end
    end
    conditions
  end

  def should_include_keyword_field?(field)
    @options['keyword_fields']['fields'].blank? || @options['keyword_fields']['fields'].include?(field)
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

  def build_search_team_tasks_conditions
    conditions = []
    return conditions unless @options.has_key?('team_tasks') && @options['team_tasks'].class.name == 'Array'
    @options['team_tasks'].each do |tt|
      must_c = []
      must_c << { term: { "task_responses.team_task_id": tt['id'] } } if tt.has_key?('id')
      response_type = tt['response_type'] ||= 'choice'
      if tt['response'] == 'NO_VALUE'
        return [{
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
        }]
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

  def build_search_sort
    # As per spec, for now the team task sort should be just based on "has data" / "has no data"
    # Items without data appear first
    if @options['sort'] =~ /^task_value_[0-9]+$/
      team_task_id = @options['sort'].match(/^task_value_([0-9]+)$/)[1].to_i
      missing = {
        asc: '_first',
        desc: '_last'
      }[@options['sort_type'].to_s.downcase.to_sym]
      return [
        {
          'task_responses.id': {
            order: @options['sort_type'],
            missing: missing,
            nested: {
              path: 'task_responses',
              filter: {
                bool: {
                  must: [
                    { term: { 'task_responses.team_task_id': team_task_id } },
                    { exists: { field: 'task_responses.value' } }
                  ]
                }
              }
            }
          }
        }
      ]
    elsif SORT_MAPPING.keys.include?(@options['sort'].to_s)
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
    return [] if @options["tags"].blank? || @options["tags"].class.name != 'Array'
    tags_c = search_tags_query(@options["tags"])
    [tags_c]
  end

  def build_search_integer_terms_query(field, key)
    return [] unless @options[key].is_a?(Array)
    [{ terms: { "#{field}": @options[key].map(&:to_i) } }]
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

  def build_search_report_status_conditions
    return [] if @options['report_status'].blank? || !@options['report_status'].is_a?(Array)
    statuses = []
    @options['report_status'].each do |status_name|
      status_id = ['unpublished', 'paused', 'published'].index(status_name) || -1 # Invalidate the query if an invalid status is passed
      statuses << status_id
    end
    [{ terms: { report_status: statuses } }]
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
    [:created_at, :updated_at, :last_seen, :published_at].each do |name|
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
  def build_search_numeric_range_filter
    conditions = []
    return conditions if @options['range_numeric'].blank?
    @options['range_numeric'].each do |field, values|
      range_condition = format_mumeric_range_condition(field, values)
      conditions << range_condition unless range_condition.blank?
    end
    conditions
  end

  def format_mumeric_range_condition(field, values)
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
    !@options['range'].blank? && (@options['range'].keys.include?('last_seen') || @options['range'].keys.include?('published_at'))
  end
end
