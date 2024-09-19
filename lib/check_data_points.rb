class CheckDataPoints
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
      smooch_request_type: ['relevant_search_result_requests', 'irrelevant_search_result_requests'],
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
    .joins("INNER JOIN tipline_newsletters tnl ON tipline_newsletter_deliveries.tipline_newsletter_id = tnl.id")
    .where('tnl.team_id = ?', team_id)
    .where(created_at: start_date..end_date)
    self.query_based_on_granularity(query, granularity, 'tipline_newsletter_deliveries.created_at')
  end

  # 6) Number of Media received, by type
  def self.media_received_by_type(team_id, start_date, end_date)
    bot = BotUser.smooch_user
    start_date, end_date = self.parse_start_end_dates(start_date, end_date)
    query = ProjectMedia.where(team_id: team_id, user_id: bot.id, created_at: start_date..end_date)
    .joins(:media).group('medias.type')
    query.count
  end

  # Top clusters
  def self.top_clusters(team_id, start_date, end_date)

  end

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
end
