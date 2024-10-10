class TeamStatistics
  def initialize(team, period, language, platform)
    @team = team
    @period = period
    @language = language
    @platform = platform
  end

  # For articles

  # TODO
  def number_of_articles_created
    data = {}
    time_range.each do |day|
      data[day] = rand(100)
    end
    data
  end

  # TODO
  def number_of_articles_updated
    data = {}
    time_range.each do |day|
      data[day] = rand(100)
    end
    data
  end

  # TODO
  def number_of_explainers_created
    rand(1000)
  end

  # TODO
  def number_of_fact_checks_created
    rand(1000)
  end

  # TODO
  def number_of_published_fact_checks
    rand(1000)
  end

  # TODO
  def number_of_fact_checks_by_rating
    { 'Unstarted' => rand(100), 'In Progress' => rand(100), 'False' => rand(100), 'True' => rand(100) }
  end

  # TODO
  def top_articles_sent
    { 'The sky is blue' => rand(100), 'Earth is round' => rand(100), 'Soup is dinner' => rand(100) }
  end

  # TODO
  def top_articles_tags
    { 'tag1' => rand(100), 'tag2' => rand(100), 'tag3' => rand(100), 'tag4' => rand(100), 'tag5' => rand(100) }
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
      last_week: 1.week,
      last_month: 1.month,
      last_year: 1.year
    }[@period.to_sym]
    (Time.now.ago(ago).to_datetime..Time.now.to_datetime).to_a
  end
end
