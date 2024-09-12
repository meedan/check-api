class CheckDataPoints
  def self.tipline_requests(team_id, date = nil)
  	# date in format `2023-08-23`
  	date = begin DateTime.parse(date) rescue nil end
  	query = TiplineRequest.where(team_id: team_id)
  	query = query.where(created_at: date.all_day) unless date.nil?
  	query.count
  end
end