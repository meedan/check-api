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

  def item_belongs_to_feed?(pm)
    current_team = Team.current
    Team.current = Team.find(pm.team_id)
    items = CheckSearch.new({ feed_id: self.id, eslimit: 10000 }.to_json, nil, pm.team_id).medias.map(&:id)
    Team.current = current_team
    items.include?(pm.id)
  end

  # This takes some time to run because it involves external HTTP requests and writes to the database:
  # 1) If the query contains a media URL, it will be downloaded... if it contains some other URL, it will be sent to Pender
  # 2) Requests will be made to Alegre in order to index the request media and to look for similar requests
  # 3) Save request in the database
  # 4) Save relationships between request and results in the database
  # So please consider always calling this method in background.
  def self.save_request(feed_id, type, query, webhook_url, result_ids)
    media = Request.get_media_from_query(type, query, feed_id)
    request = Request.create!(feed_id: feed_id, request_type: type, content: query, webhook_url: webhook_url, media: media, skip_check_ability: true)
    unless result_ids.blank?
      result_ids.each { |id| ProjectMediaRequest.create!(project_media_id: id, request_id: request.id, skip_check_ability: true) }
    end
    request.attach_to_similar_request!
    request
  end

  # This makes one HTTP request for each request, so please consider calling this method in background
  def self.notify_subscribers(pm, title, summary, url)
    pm.team.feeds.each do |feed|
      if feed.item_belongs_to_feed?(pm)
        # Find cluster
        request = Request.where(feed_id: feed.id, media_id: pm.media_id).last
        unless request.nil?
          request = request.similar_to_request || request
          request.call_webhook(pm, title, summary, url)
          request.similar_requests.find_each { |similar_request| similar_request.call_webhook(pm, title, summary, url) }
        end
      end
    end
  end
end
