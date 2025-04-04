class CheckDataPoints
  class << self
    SEARCH_RESULT_TYPES = ['relevant_search_result_requests', 'irrelevant_search_result_requests', 'timeout_search_requests']
    GRANULARITY_VALUES = ['year', 'quarter', 'month', 'week', 'day']

    # Number of tipline messages
    def tipline_messages(team_id, start_date, end_date, granularity = nil, platform = nil, language = nil, direction = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      query = TiplineMessage.where(team_id: team_id, created_at: start_date..end_date, state: ['sent', 'received'])
      query = query.where(direction: direction) unless direction.nil?
      query_based_on_granularity(query, platform, language, granularity)
    end

    # Number of tipline requests
    def tipline_requests(team_id, start_date, end_date, granularity = nil, platform = nil, language = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      query = TiplineRequest.where(team_id: team_id, created_at: start_date..end_date)
      query_based_on_granularity(query, platform, language, granularity)
    end

    # Number of tipline requests grouped by type of search result
    def tipline_requests_by_search_type(team_id, start_date, end_date, platform = nil, language = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      query = TiplineRequest.where(
        team_id: team_id,
        smooch_request_type: SEARCH_RESULT_TYPES,
        created_at: start_date..end_date,
      )
      query = query.where(platform: platform) unless platform.blank?
      query = query.where(language: language) unless language.blank?
      query.group('smooch_request_type').count
    end

    # Number of Subscribers
    def tipline_subscriptions(team_id, start_date, end_date, granularity = nil, platform = nil, language = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      query = TiplineSubscription.where(team_id: team_id, created_at: start_date..end_date)
      query_based_on_granularity(query, platform, language, granularity)
    end

    # Number of Newsletters sent
    def newsletters_sent(team_id, start_date, end_date, granularity = nil, platform = nil, language = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      query = TiplineNewsletterDelivery
      .joins(:tipline_newsletter)
      .where('tipline_newsletters.team_id': team_id)
      .where(created_at: start_date..end_date)
      query_based_on_granularity(query, platform, language, granularity, 'newsletter')
    end

    # Number of Media received, by type
    def media_received_by_type(team_id, start_date, end_date)
      bot = BotUser.smooch_user
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      ProjectMedia.where(team_id: team_id, user_id: bot.id, created_at: start_date..end_date)
      .joins(:media).group('medias.type').count
    end

    # Top clusters
    def top_clusters(team_id, start_date, end_date, limit = 5, range_field = 'created_at', language = nil, language_field = 'language', platform = nil)
      elastic_search_top_items(team_id, start_date, end_date, limit, false, range_field, language, language_field, platform)
    end

    # Top media tags
    def top_media_tags(team_id, start_date, end_date, limit = 5, range_field = 'created_at', language = nil, language_field = 'language', platform = nil)
      elastic_search_top_items(team_id, start_date, end_date, limit, true, range_field, language, language_field, platform)
    end

    # Articles sent
    def articles_sent(team_id, start_date, end_date, platform = nil, language = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      # Get number of articles sent as search results
      search_results_query = TiplineRequest.where(team_id: team_id, smooch_request_type: SEARCH_RESULT_TYPES, created_at: start_date..end_date)
      search_results_query = search_results_query.where(platform: platform) unless platform.blank?
      search_results_query = search_results_query.where(language: language) unless language.blank?
      search_results_count = search_results_query.count
      # Get the number of articles sent as reports
      reports_query = TiplineRequest
      .where(team_id: team_id, created_at: start_date..end_date)
      .where('smooch_report_received_at > 0 OR smooch_report_update_received_at > 0 OR smooch_report_sent_at > 0 OR smooch_report_correction_sent_at > 0')
      reports_query = reports_query.where(platform: platform) unless platform.blank?
      reports_query = reports_query.where(language: language) unless language.blank?
      reports_count = reports_query.count
      search_results_count + reports_count
    end

    # Average response time
    def average_response_time(team_id, start_date, end_date, platform = nil, language = nil)
      query = TiplineRequest.where(team_id: team_id, created_at: start_date..end_date)
      query = query.where('(smooch_report_received_at > 0 OR smooch_report_update_received_at > 0 OR smooch_report_sent_at > 0 OR smooch_report_correction_sent_at > 0 OR first_manual_response_at > 0)')
      query = query.where(platform: platform) unless platform.blank?
      query = query.where(language: language) unless language.blank?
      average = <<-SQL.squish
        (SELECT MIN(x)
           FROM unnest(ARRAY[smooch_report_received_at,
                             smooch_report_update_received_at,
                             smooch_report_sent_at,
                             smooch_report_correction_sent_at,
                             first_manual_response_at]) AS x
          WHERE x IS NOT NULL AND x > 0)
        - CAST(DATE_PART('EPOCH', created_at::timestamp) AS INTEGER)
      SQL
      query.average(average).to_f
    end

    # All users
    def all_users(team_id, start_date, end_date, platform = nil, language = nil)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      query = TiplineRequest.where(team_id: team_id, created_at: start_date..end_date)
      query = query.where(platform: platform) unless platform.blank?
      query = query.where(language: language) unless language.blank?
      query.count('DISTINCT(tipline_user_uid)')
    end

    # Returning users
    def returning_users(team_id, start_date, end_date, platform = nil, language = nil)
      # Number of returning users (at least one session in the current month, and at least one session in the last previous 2 months)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      uids_query = TiplineRequest.where(team_id: team_id, created_at: start_date.ago(2.months)..start_date)
      uids_query = uids_query.where(platform: platform) unless platform.blank?
      uids_query = uids_query.where(language: language) unless language.blank?
      uids = uids_query.select(:tipline_user_uid).map(&:tipline_user_uid).uniq
      query = TiplineRequest.where(team_id: team_id, tipline_user_uid: uids, created_at: start_date..end_date)
      query = query.where(platform: platform) unless platform.blank?
      query = query.where(language: language) unless language.blank?
      query.count('DISTINCT(tipline_user_uid)')
    end

    # New users
    def new_users(team_id, start_date, end_date)
      start_date, end_date = parse_start_end_dates(start_date, end_date)
      Annotation.where(annotation_type: 'smooch_user', annotated_type: 'Team', annotated_id: team_id)
      .joins("INNER JOIN dynamic_annotation_fields fs ON fs.annotation_id = annotations.id AND fs.field_name = 'smooch_user_id'")
      .where('annotations.created_at': start_date..end_date)
      .count
    end

    private

    def parse_start_end_dates(start_date, end_date)
      # date format is `2023-08-23`
      start_date = Time.parse(start_date).beginning_of_day
      end_date = Time.parse(end_date).end_of_day
      raise 'End date should be greater than start date' if start_date > end_date
      return start_date, end_date
    end

    def query_based_on_granularity(query, platform, language, granularity, type = nil)
      query = query.where(platform: platform) unless platform.blank?
      query = query.where(language: language) unless language.blank?
      # For PG the allowed values for granularity can be one of the following
      # [millennium, century, decade, year, quarter, month, week, day, hour,
      # minute, second, milliseconds, microseconds]
      # But I'll limit the value to the following [year, quarter, month, week, day]
      if GRANULARITY_VALUES.include?(granularity)
        if type == 'newsletter'
          query.group("date_trunc('#{granularity}', tipline_newsletter_deliveries.created_at)").count
        else
          query.group("date_trunc('#{granularity}', created_at)").count
        end
      else
        query.count
      end
    end

    def elastic_search_top_items(team_id, start_date, end_date, limit, with_tags = false, range_field = 'created_at', language = nil, language_field = 'language', platform = nil)
      data = {}
      query = {
        range: { range_field => { start_time: start_date, end_time: end_date } },
        demand: { min: 1 },
        sort: 'demand',
        eslimit: limit
      }
      query[:tags_as_sentence] = { min: 1 } if with_tags
      query[language_field.to_sym] = [language].flatten if language
      query[:channels] = [CheckChannels::ChannelCodes.all_channels['TIPLINE'][platform.upcase]] if platform
      result = CheckSearch.new(query.to_json, nil, team_id)
      result.medias.each{ |pm| data[pm.id] = pm.demand }
      data
    end
  end
end
