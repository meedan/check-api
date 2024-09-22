class CheckDataPoints
  SEARCH_RESULT_TYPES = ['relevant_search_result_requests', 'irrelevant_search_result_requests', 'timeout_search_requests']

  # 1) Number of tipline messages
  def self.tipline_messages(team_id, start_date, end_date, granularity = nil)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = TiplineMessage.where(team_id: team_id, created_at: start_date..end_date)
    self.query_based_on_granularity(query, granularity)
  end

  # 2) Number of tipline requests
  def self.tipline_requests(team_id, start_date, end_date, granularity = nil)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = TiplineRequest.where(team_id: team_id, created_at: start_date..end_date)
    self.query_based_on_granularity(query, granularity)
  end

  # 3) Number of tipline requests grouped by type of search result
  def self.tipline_requests_by_search_type(team_id, start_date, end_date)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    TiplineRequest.where(
      team_id: team_id,
      smooch_request_type: SEARCH_RESULT_TYPES,
      created_at: start_date..end_date,
    ).group('smooch_request_type').count
  end

  # 4) Number of Subscribers
  def self.tipline_subscriptions(team_id, start_date, end_date, granularity = nil)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = TiplineSubscription.where(team_id: team_id, created_at: start_date..end_date)
    self.query_based_on_granularity(query, granularity)
  end

  # 5) Number of Newsletters sent
  def self.newsletters_sent(team_id, start_date, end_date, granularity = nil)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = TiplineNewsletterDelivery
    .joins(:tipline_newsletter)
    .where('tipline_newsletters.team_id': team.id)
    .where(created_at: start_date..end_date)
    self.query_based_on_granularity(query, granularity, 'tipline_newsletter_deliveries.created_at')
  end

  # 6) Number of Media received, by type
  def self.media_received_by_type(team_id, start_date, end_date)
    bot = BotUser.smooch_user
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    ProjectMedia.where(team_id: team_id, user_id: bot.id, created_at: start_date..end_date)
    .joins(:media).group('medias.type').count
  end

  # 7) Top clusters
  def self.top_clusters(team_id, start_date, end_date, limit = 5)
    result = CheckSearch.new({sort: 'demand', eslimit: limit }.to_json, nil, team.id)
    result.medias.collect{|pm| { id: pm.id, demand: pm.demand } }
  end

  # 8) Top media tags
  def self.top_media_tags(team_id, start_date, end_date, limit = 5)
    result = CheckSearch.new({sort: 'demand', eslimit: limit }.to_json, nil, team.id)
    result.medias.collect{|pm| { id: pm.id, demand: pm.demand } }
  end

  # 9) Articles sent
  def self.articles_sent()
  end

  # 10) Average response time
  def average_response_time()
  end

  # 11) Number of users
  # 11.1) All users
  def all_users(team_id, start_date, end_date, granularity = nil)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = TiplineRequest.where(team_id: team_id, created_at: start_date..end_date)
    self.query_tipline_users_based_on_granularity(query, granularity)
  end

  # 11.2) Returning users
  def returning_users(team_id, start_date, end_date, granularity = nil)
    # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    uids = TiplineRequest.where(team_id: team_id, created_at: start_date.ago(2.months)..start_date).map(&:tipline_user_uid).uniq
    query = TiplineRequest.where(team_id: team_id, tipline_user_uid: uids, created_at: start_date..end_date)
    self.query_tipline_users_based_on_granularity(query, granularity)
  end

  # 11.3) New users
  def new_users(team_id, start_date, end_date, granularity = nil)
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = TiplineRequest.where(team_id: team_id)
    .joins("INNER JOIN annotations a ON tipline_requests.team_id = a.annotated_id")
    .where('a.annotation_type': 'smooch_user', 'a.annotated_type': 'Team')
    .where('a.created_at': start_date..end_date)
    self.query_tipline_users_based_on_granularity(query, granularity)
  end

  private

  def self.parse_start_end_dates(start_date, end_date)
    # date format is `2023-08-23`
    start_date = Time.parse(start_date)
    end_date = Time.parse(end_date)
    raise 'End date should be greater than start date' if start_date > end_date
    return start_date, end_date
  end

  def self.query_based_on_granularity(query, granularity, col_name = 'created_at')
    # For PG the allowed values for granularity can be one of the following
    # [millennium, century, decade, year, quarter, month, week, day, hour,
    # minute, second, milliseconds, microseconds]
    # But I'll limit the value to the following [year, quarter, month, week, day]
    if %w(year quarter month week day).include?(granularity)
      query.group("date_trunc('#{granularity}', #{col_name})").count
    else
      query.count
    end
  end

  def self.query_tipline_users_based_on_granularity(query, granularity)
    if %w(year quarter month week day).include?(granularity)
      query.group("date_trunc('#{granularity}', created_at)").count('DISTINCT(tipline_user_uid)')
    else
      query.count('DISTINCT(tipline_user_uid)')
    end
  end
end
