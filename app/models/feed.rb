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

  # This takes some time to run because it involves external HTTP requests:
  # 1) If the query contains a media URL, it will be downloaded... if it contains some other URL, it will be sent to Pender
  # 2) Requests will be made to Alegre in order to index the request media and to look for similar requests
  # So please consider always calling this method in background.
  def self.save_request(feed_id, type, query)
    media = Request.get_media_from_query(type, query)
    request = Request.create!(feed_id: feed_id, request_type: type, content: query, media: media, skip_check_ability: true)
    request.attach_to_similar_request!
    request
  end
end
