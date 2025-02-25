class ListExport
  TYPES = [:media, :feed, :fact_check, :explainer, :articles_dashboard, :tipline_dashboard, :articles]

  def initialize(type, query, team_id)
    @type = type
    @query = query
    @parsed_query = JSON.parse(@query).with_indifferent_access
    @team_id = team_id
    @team = Team.find(team_id)
    @feed = Feed.find(@parsed_query['feed_id']) if type == :feed && @team.is_part_of_feed?(Feed.find(@parsed_query['feed_id']))
    raise "Invalid export type '#{type}'. Should be one of: #{TYPES}" unless TYPES.include?(type)
  end

  def number_of_rows
    case @type
    when :media
      CheckSearch.new(@query, nil, @team_id).number_of_results
    when :feed
      @feed.clusters_count(@parsed_query)
    when :fact_check
      @team.filtered_fact_checks(@parsed_query).count
    when :explainer
      @team.filtered_explainers(@parsed_query).count
    when :articles
      @team.filtered_explainers(@parsed_query).count + @team.filtered_fact_checks(@parsed_query).count
    when :articles_dashboard, :tipline_dashboard
      1 # Always maintain one row for dashboard data, but use different columns for export.
    end
  end

  def generate_csv_and_send_email_in_background(user)
    ListExport.delay.generate_csv_and_send_email(self, user.id)
  end

  def generate_csv_and_send_email(user)
    # Convert to CSV
    csv_string = CSV.generate do |csv|
      self.export_data.each do |row|
        csv << row
      end
    end

    # Save to S3
    csv_file_url = CheckS3.write_presigned("export/#{@type}/#{@team_id}/#{Time.now.to_i}/#{Digest::MD5.hexdigest(@query)}.csv", 'text/csv', csv_string, CheckConfig.get('export_csv_expire', 7.days.to_i, :integer))

    # Send to e-mail
    ExportListMailer.delay.send_csv(csv_file_url, user)

    # Return path to CSV
    csv_file_url
  end

  def self.generate_csv_and_send_email(export, user_id)
    export.generate_csv_and_send_email(User.find(user_id))
  end

  private

  def export_data
    case @type
    when :media
      CheckSearch.get_exported_data(@query, @team_id)
    when :feed
      @feed.get_exported_data(@parsed_query)
    when :fact_check
      FactCheck.get_exported_data(@parsed_query, @team)
    when :explainer
      Explainer.get_exported_data(@parsed_query, @team)
    when :articles
      @team.get_articles_exported_data(@parsed_query)
    when :articles_dashboard, :tipline_dashboard
      @team.get_dashboard_exported_data(@parsed_query, @type)
    end
  end
end
