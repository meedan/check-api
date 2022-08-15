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

  def self.save_request(feed_id, type, query)
    Request.create!(feed_id: feed_id, request_type: type, content: query, skip_check_ability: true)
  end
end
