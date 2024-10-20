class TeamStatistics
  PERIODS = ['last_day', 'last_week', 'last_month', 'last_year']

  def initialize(team, period, language, platform = nil)
    @team = team
    raise ArgumentError.new('Invalid workspace provided') unless @team.is_a?(Team)
    @period = period
    raise ArgumentError.new("Invalid period provided. Allowed values: #{PERIODS.join(', ')}") unless PERIODS.include?(@period)
    @language = language
    @platform = platform
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
    fact_checks_base_query.group(:rating).count.sort.to_h
  end

  # FIXME: Only fact-checks for now - add explainers
  def top_articles_sent
    data = {}
    range = time_range.to_a
    start_date, end_date = range.first, range.last
    clusters = CheckDataPoints.top_clusters(@team.id, start_date, end_date, 5, 'last_seen', @language)
    clusters.each do |pm_id, demand|
      data[ProjectMedia.find(pm_id).fact_check_title] = demand
    end
    data
  end

  def top_articles_tags
    sql = <<-SQL
      SELECT tag, COUNT(*) as tag_count
      FROM (
        SELECT unnest(fcs.tags) AS tag FROM fact_checks fcs
          INNER JOIN claim_descriptions cds ON fcs.claim_description_id = cds.id
          WHERE cds.team_id = :team_id AND fcs.created_at BETWEEN :start_date AND :end_date AND fcs.language IN (:language)
        UNION ALL
        SELECT unnest(explainers.tags) AS tag FROM explainers
          WHERE explainers.team_id = :team_id AND explainers.created_at BETWEEN :start_date AND :end_date AND explainers.language IN (:language)
      ) AS all_tags
      GROUP BY tag
      ORDER BY tag_count DESC
      LIMIT 5
    SQL

    range = time_range.to_a
    start_date, end_date = range.first, range.last
    language = @language ? [@language] : @team.get_languages.to_a
    result = ActiveRecord::Base.connection.execute(ApplicationRecord.sanitize_sql_for_assignment([sql, team_id: @team.id, start_date: start_date, end_date: end_date, language: language]))
    data = {}
    result.each do |row|
      data[row['tag']] = row['tag_count'].to_i
    end
    data.sort.reverse.to_h
  end

  # For tiplines

  # TODO
  def number_of_messages
    rand(1000)
  end

  # TODO
  def number_of_conversations
    rand(1000)
  end

  # TODO
  def number_of_search_results_by_type
    { 'Image' => rand(100), 'Text' => rand(100), 'Audio' => rand(100), 'Video' => rand(100), 'Link' => rand(100) }
  end

  # TODO
  def average_response_type
    24.hours
  end

  # TODO
  def number_of_unique_users
    rand(1000)
  end

  # TODO
  def number_of_total_users
    rand(1000)
  end

  # TODO
  def number_of_returning_users
    rand(1000)
  end

  # TODO
  def number_of_subscribers
    rand(1000)
  end

  # TODO
  def number_of_newsletters_sent
    rand(1000)
  end

  # TODO
  def number_of_newsletters_delivered
    rand(1000)
  end

  # TODO
  def top_media_tags
    { 'tag1' => rand(100), 'tag2' => rand(100), 'tag3' => rand(100), 'tag4' => rand(100), 'tag5' => rand(100) }
  end

  # TODO
  def top_requested_media_clusters
    { 'The sky is blue' => rand(100), 'Earth is round' => rand(100), 'Soup is dinner' => rand(100) }
  end

  # TODO
  def number_of_media_received_by_type
    { 'Image' => rand(100), 'Text' => rand(100), 'Audio' => rand(100), 'Video' => rand(100), 'Link' => rand(100) }
  end

  # For both articles and tiplines

  # TODO
  def number_of_articles_sent
    rand(1000)
  end

  # TODO
  def number_of_matched_results
    rand(1000)
  end

  private

  def time_range
    ago = {
      last_day: 1.day,
      last_week: 1.week,
      last_month: 1.month,
      last_year: 1.year
    }[@period.to_sym]
    Time.now.ago(ago).to_datetime..Time.now.to_datetime
  end

  def fact_checks_base_query(timestamp_field = :created_at, group_by_day = false)
    query = FactCheck.joins(:claim_description).where('language' => @language, timestamp_field => time_range, 'claim_descriptions.team_id' => @team.id)
    query = query.where('fact_checks.created_at != fact_checks.updated_at') if timestamp_field.to_sym == :updated_at
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
    query = Explainer.where('language' => @language, timestamp_field => time_range, 'team_id' => @team.id)
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
end
