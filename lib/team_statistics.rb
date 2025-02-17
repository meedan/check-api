class TeamStatistics
  PERIODS = ['past_week', 'past_2_weeks', 'past_month', 'past_3_months', 'past_6_months', 'year_to_date']

  PLATFORMS = Bot::Smooch::SUPPORTED_INTEGRATION_NAMES

  def initialize(team, period, language, platform = nil)
    @team = team
    unless @team.is_a?(Team)
      raise ArgumentError.new('Invalid workspace provided')
    end

    @period = period
    unless PERIODS.include?(@period)
      raise ArgumentError.new("Invalid period provided. Allowed values: #{PERIODS.join(', ')}")
    end

    range = time_range.to_a
    @start_date, @end_date = range.first.to_datetime.beginning_of_day, range.last.to_datetime.end_of_day
    @start_date_str, @end_date_str = @start_date.strftime('%Y-%m-%d'), @end_date.strftime('%Y-%m-%d')

    @platform = platform
    if !@platform.blank? && !PLATFORMS.keys.include?(@platform)
      # For `Bot::Smooch::SUPPORTED_INTEGRATION_NAMES`, the keys (e.g., 'whatsapp') are used by `TiplineRequest`,
      # while the values (e.g., 'WhatsApp') are used by `TiplineMessage`
      raise ArgumentError.new("Invalid platform provided. Allowed values: #{PLATFORMS.keys.join(', ')}")
    end
    @platform_name = PLATFORMS[@platform] unless @platform.blank?

    @language = language
    @all_languages = [@team.get_languages.to_a, 'und'].flatten
  end

  # For GraphQL
  def id
    Base64.encode64("TeamStatistics/#{@team.id}")
  end

  # For articles

  def number_of_articles_created_by_date
    number_of_articles_saved_by_date(:created_at)
  end

  def number_of_articles_updated_by_date
    number_of_articles_saved_by_date(:updated_at)
  end

  def number_of_explainers_created
    explainers_base_query.count
  end

  def number_of_fact_checks_created
    fact_checks_base_query.count
  end

  def number_of_published_fact_checks
    fact_checks_base_query.where(report_status: 'published').count
  end

  def number_of_fact_checks_by_rating
    data = {}
    fact_checks_base_query.group(:rating).count.each do |status_id, count|
      data[status_id.to_s] = count
    end
    data.sort.to_h
  end

  # FIXME: Only fact-checks for now (need to add explainers) and the "demand" is across languages and platforms
  def top_articles_sent
    data = []
    clusters = CheckDataPoints.top_clusters(@team.id, @start_date, @end_date, 5, 'last_seen', @language || @all_languages, 'fc_language')
    clusters.each do |pm_id, demand|
      item = ProjectMedia.find(pm_id)
      title = item.fact_check_title || item.title
      data << { id: item.fact_check_id, label: title, value: demand }
    end
    data.sort_by{ |object| object[:value] }.reverse
  end

  def top_articles_tags
    sql = <<-SQL
      SELECT tag, COUNT(*) as tag_count
      FROM (
        SELECT unnest(fcs.tags) AS tag FROM fact_checks fcs
          INNER JOIN claim_descriptions cds ON fcs.claim_description_id = cds.id
          WHERE cds.team_id = :team_id AND fcs.updated_at BETWEEN :start_date AND :end_date AND fcs.language IN (:language)
        UNION ALL
        SELECT unnest(explainers.tags) AS tag FROM explainers
          WHERE explainers.team_id = :team_id AND explainers.updated_at BETWEEN :start_date AND :end_date AND explainers.language IN (:language)
      ) AS all_tags
      GROUP BY tag
      ORDER BY tag_count DESC
      LIMIT 5
    SQL

    language = @language ? [@language] : @all_languages
    result = ActiveRecord::Base.connection.execute(ApplicationRecord.sanitize_sql_for_assignment([sql, team_id: @team.id, start_date: @start_date, end_date: @end_date, language: language]))
    data = []
    result.each do |row|
      data << { id: row['tag'], label: row['tag'], value: row['tag_count'].to_i }
    end
    data.sort_by{ |object| object[:value] }.reverse
  end

  # For tiplines

  def number_of_messages
    CheckDataPoints.tipline_messages(@team.id, @start_date_str, @end_date_str, nil, @platform_name, @language)
  end

  def number_of_incoming_messages
    CheckDataPoints.tipline_messages(@team.id, @start_date_str, @end_date_str, nil, @platform_name, @language, 'incoming')
  end

  def number_of_outgoing_messages
    CheckDataPoints.tipline_messages(@team.id, @start_date_str, @end_date_str, nil, @platform_name, @language, 'outgoing')
  end

  def number_of_conversations
    CheckDataPoints.tipline_requests(@team.id, @start_date_str, @end_date_str, nil, @platform, @language)
  end

  def number_of_messages_by_date
    data = CheckDataPoints.tipline_messages(@team.id, @start_date_str, @end_date_str, 'day', @platform_name, @language)
    number_of_tipline_data_points_by_date(data)
  end

  def number_of_conversations_by_date
    data = CheckDataPoints.tipline_requests(@team.id, @start_date_str, @end_date_str, 'day', @platform, @language)
    number_of_tipline_data_points_by_date(data)
  end

  def number_of_search_results_by_feedback_type
    mapping = {
      relevant_search_result_requests: 'Positive',
      irrelevant_search_result_requests: 'Negative',
      timeout_search_requests: 'No Response'
    }
    data = {
      'Positive' => 0,
      'Negative' => 0,
      'No Response' => 0
    }
    CheckDataPoints.tipline_requests_by_search_type(@team.id, @start_date_str, @end_date_str, @platform, @language).each do |type, count|
      data[mapping[type.to_sym]] = count
    end
    data
  end

  def average_response_time
    CheckDataPoints.average_response_time(@team.id, @start_date, @end_date, @platform, @language)
  end

  def number_of_unique_users
    number_of_total_users - number_of_returning_users
  end

  def number_of_total_users
    CheckDataPoints.all_users(@team.id, @start_date_str, @end_date_str, @platform, @language)
  end

  def number_of_returning_users
    CheckDataPoints.returning_users(@team.id, @start_date_str, @end_date_str, @platform, @language)
  end

  def number_of_subscribers
    CheckDataPoints.tipline_subscriptions(@team.id, @team.created_at.strftime('%Y-%m-%d'), @end_date_str, nil, @platform_name, @language)
  end

  def number_of_new_subscribers
    CheckDataPoints.tipline_subscriptions(@team.id, @start_date_str, @end_date_str, nil, @platform_name, @language)
  end

  def number_of_newsletters_sent
    number_of_newsletters('sent')
  end

  def number_of_newsletters_delivered
    number_of_newsletters('delivered')
  end

  def number_of_media_received_by_media_type
    conditions = { team_id: @team.id, created_at: @start_date..@end_date }
    conditions[:language] = @language unless @language.blank?
    conditions[:platform] = @platform unless @platform.blank?
    data = TiplineRequest
           .joins("INNER JOIN project_medias pm ON tipline_requests.associated_type = 'ProjectMedia' AND pm.id = tipline_requests.associated_id")
           .joins("INNER JOIN medias m ON m.id = pm.media_id")
           .where(conditions)
           .group('m.type')
           .count
    { 'Claim' => 0, 'Link' => 0, 'UploadedAudio' => 0, 'UploadedImage' => 0, 'UploadedVideo' => 0 }.merge(data).reject{ |k, _v| k == 'Blank' }
  end

  # FIXME: The "demand" is across languages and platforms
  def top_requested_media_clusters
    data = []
    clusters = CheckDataPoints.top_clusters(@team.id, @start_date, @end_date, 5, 'last_seen', @language || @all_languages, 'request_language', @platform)
    clusters.each do |pm_id, demand|
      item = ProjectMedia.find(pm_id)
      data << { id: item.id, label: item.title, value: demand }
    end
    data.sort_by{ |object| object[:value] }.reverse
  end

  # FIXME: The "demand" is across languages and platforms
  def top_media_tags
    tags = {}
    clusters = CheckDataPoints.top_media_tags(@team.id, @start_date, @end_date, 20, 'last_seen', @language || @all_languages, 'language', @platform)
    clusters.each do |pm_id, demand|
      item = ProjectMedia.find(pm_id)
      item.tags_as_sentence.split(',').map(&:strip).each do |tag|
        tags[tag] ||= 0
        tags[tag] += demand
      end
    end
    data = []
    tags.each { |tag, value| data << { id: tag, label: tag, value: value } }
    data.sort_by{ |object| object[:value] }.reverse.first(5)
  end

  # For both articles and tiplines

  def number_of_articles_sent
    CheckDataPoints.articles_sent(@team.id, @start_date_str, @end_date_str, @platform, @language)
  end

  def number_of_matched_results_by_article_type
    query = TiplineRequest.where(team_id: @team.id, created_at: @start_date..@end_date)
    query = query.where(platform: @platform) unless @platform.blank?
    query = query.where(language: @language) unless @language.blank?
    { 'FactCheck' => query.joins(project_media: { claim_description: :fact_check }).count, 'Explainer' => query.joins(project_media: :explainers).count }
  end

  private

  def time_range
    ago = {
      past_week: 1.week,
      past_2_weeks: 2.weeks,
      past_month: 1.month,
      past_3_months: 3.months,
      past_6_months: 6.months
    }[@period.to_sym]
    from = Time.now.ago(ago) unless ago.nil?
    from = Time.now.beginning_of_year if @period.to_s == 'year_to_date'
    from.to_datetime.beginning_of_day..Time.now.to_datetime.end_of_day
  end

  def fact_checks_base_query(timestamp_field = :created_at, group_by_day = false)
    query = FactCheck.joins(:claim_description).where(timestamp_field => time_range, 'claim_descriptions.team_id' => @team.id)
    query = query.where('fact_checks.created_at != fact_checks.updated_at') if timestamp_field.to_sym == :updated_at
    query = query.where(language: @language) unless @language.blank?
    if group_by_day
      # Avoid SQL injection warning
      group = {
        created_at: "date_trunc('day', fact_checks.created_at)",
        updated_at: "date_trunc('day', fact_checks.updated_at)"
      }[timestamp_field.to_sym]
      query = query.group(group)
    end
    query
  end

  def explainers_base_query(timestamp_field = :created_at, group_by_day = false)
    query = Explainer.where(timestamp_field => time_range, 'team_id' => @team.id)
    query = query.where(language: @language) unless @language.blank?
    query = query.where('explainers.created_at != explainers.updated_at') if timestamp_field.to_sym == :updated_at
    if group_by_day
      # Avoid SQL injection warning
      group = {
        created_at: "date_trunc('day', explainers.created_at)",
        updated_at: "date_trunc('day', explainers.updated_at)"
      }[timestamp_field.to_sym]
      query = query.group(group)
    end
    query
  end

  def number_of_articles_saved_by_date(timestamp_field) # timestamp_field = :created_at or :updated_at
    raise ArgumentError if timestamp_field != :created_at && timestamp_field != :updated_at
    number_of_fact_checks = fact_checks_base_query(timestamp_field, true).count
    number_of_explainers = explainers_base_query(timestamp_field, true).count
    number_of_articles = {}

    # Pre-fill with zeros
    time_range.to_a.each do |day|
      number_of_articles[day.strftime("%Y-%m-%d")] = 0
    end

    # Replace zeros by the days we have data for
    (number_of_fact_checks.keys + number_of_explainers.keys).uniq.sort.each do |day|
      number_of_articles[day.strftime("%Y-%m-%d")] = number_of_fact_checks[day].to_i + number_of_explainers[day].to_i
    end

    number_of_articles
  end

  def number_of_tipline_data_points_by_date(results)
    data = {}
    # Pre-fill with zeros
    time_range.to_a.each do |day|
      data[day.strftime("%Y-%m-%d")] = 0
    end
    results.each do |day, count|
      data[day.strftime("%Y-%m-%d")] = count
    end
    data
  end

  def number_of_newsletters(state)
    query = TiplineMessage.where(created_at: @start_date..@end_date, team_id: @team.id, state: state, event: 'newsletter')
    query = query.where(language: @language) unless @language.blank?
    query = query.where(platform: @platform_name) unless @platform.blank?
    query.count
  end
end
