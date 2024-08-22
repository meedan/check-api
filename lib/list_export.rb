class ListExport
  TYPES = [:article, :feed, :media]

  def initialize(type, query, team_id)
    @type = type
    @query = query
    @team_id = team_id
    raise "Invalid export type '#{type}'. Should be one of: #{TYPES}" unless TYPES.include?(type)
  end

  def number_of_rows
    case @type
    when :media
      CheckSearch.new(@query, nil, @team_id).number_of_results
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
    end
  end
end
