module SearchHelper
  def format_time_with_timezone(time, tz)
    begin
      Time.use_zone(tz) { Time.zone.parse(time) }
    rescue StandardError
      nil
    end
  end

  def get_from_and_to_values(values, tz)
    # condition_type = 'less_than', 'more_than', 'is_between'
    condition_type = values.dig('condition') || 'is_between'
    from = nil
    to = nil
    if ['less_than', 'more_than'].include?(condition_type)
      period = values.dig('period').to_i
      period_date = case values.dig('period_type').downcase
                  when 'd'
                    Time.now - period.day
                  when 'w'
                    Time.now - period.week
                  when 'm'
                    Time.now - period.month
                  when 'y'
                    Time.now - period.year
                  end
      condition_date = period_date.blank? ? nil : format_time_with_timezone(period_date.to_s, tz)
      if condition_type == 'less_than'
        from = condition_date
      else
        to = condition_date
      end
    else
      from = format_time_with_timezone(values.dig('start_time'), tz)
      to = format_time_with_timezone(values.dig('end_time'), tz)
    end
    return from, to
  end

  def format_times_search_range_filter(values, timezone)
    return if values.blank?
    tz = (!timezone.blank? && ActiveSupport::TimeZone[timezone]) ? timezone : 'UTC'
    from, to = get_from_and_to_values(values, tz)
    return if from.blank? && to.blank?
    from ||= DateTime.new
    to ||= DateTime.now.in_time_zone(tz)
    to = to.end_of_day if to.strftime('%T') == '00:00:00'
    [from, to]
  end
end
