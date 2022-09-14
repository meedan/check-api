class Feed < ApplicationRecord
  check_settings

  has_many :requests
  has_many :feed_teams
  has_many :teams, through: :feed_teams

  PROHIBITED_FILTERS = ['team_id', 'feed_id', 'clusterize']

  # Filters for the whole feed: applies to all data from all teams
  def get_feed_filters
    filters = self.filters.to_h.reject{ |k, _v| PROHIBITED_FILTERS.include?(k.to_s) }
    filters.merge!({ 'report_status' => ['published'] }) if self.published
    filters
  end

  # Filters defined by each team
  def get_team_filters
    filters = []
    self.feed_teams.each do |ft|
      if ft.sharing_enabled?
        filters << ft.filters.to_h.reject{ |k, _v| PROHIBITED_FILTERS.include?(k.to_s) }.merge({ 'team_id' => ft.team_id })
      end
    end
    filters
  end

  def current_feed_team
    self.feed_teams.where(team_id: Team.current&.id).last
  end

  def teams_count
    self.teams.count
  end

  def requests_count
    self.requests.count
  end

  def root_requests_count
    self.requests.where(request_id: nil).count
  end

  # This takes some time to run because it involves external HTTP requests and writes to the database:
  # 1) If the query contains a media URL, it will be downloaded... if it contains some other URL, it will be sent to Pender
  # 2) Requests will be made to Alegre in order to index the request media and to look for similar requests
  # 3) Save request in the database
  # 4) Save relationships between request and results in the database
  # So please consider always calling this method in background.
  def self.save_request(feed_id, type, query, result_ids)
    media = Request.get_media_from_query(type, query)
    request = Request.create!(feed_id: feed_id, request_type: type, content: query, media: media, skip_check_ability: true)
    unless result_ids.blank?
      result_ids.each { |id| ProjectMediaRequest.create!(project_media_id: id, request_id: request.id, skip_check_ability: true) }
    end
    request.attach_to_similar_request!
    request
  end
end
