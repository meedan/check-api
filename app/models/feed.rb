class Feed < ApplicationRecord
  include SearchHelper

  check_settings

  has_many :requests
  has_many :feed_teams
  has_many :teams, through: :feed_teams
  belongs_to :user, optional: true
  belongs_to :saved_search, optional: true

  before_validation :set_user, on: :create
  validates_presence_of :name, :description
  validate :licenses_in_allowed_values

  PROHIBITED_FILTERS = ['team_id', 'feed_id', 'clusterize']
  LICENSES = { 1 => 'academic', 2 => 'commercial', 3 => 'open_source' }

  # Filters for the whole feed: applies to all data from all teams
  def get_feed_filters
    filters = self.filters.to_h.reject{ |k, _v| PROHIBITED_FILTERS.include?(k.to_s) }
    filters.merge!({ 'report_status' => ['published'] }) if self.published
    filters
  end

  # def filters=(filters)
  #   ss = self.saved_search
  #   ss.filters = filters
  #   ss.skip_check_ability = true
  #   ss.save!
  # end

  def filters
    self.saved_search.filters
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

  def project_media_ids(team_id)
    team = Team.find_by_id(team_id.to_i)
    return [] if team.nil?
    current_team = Team.current
    Team.current = team
    ids = CheckSearch.new({ feed_id: self.id, eslimit: 10000 }.to_json, nil, team_id).medias.map(&:id) # FIXME: Limited at 10000
    Team.current = current_team
    ids
  end

  def item_belongs_to_feed?(pm)
    items = self.project_media_ids(pm.team_id)
    items.include?(pm.id)
  end

  def search(args = {})
    query = Request.where(request_id: args['request_id'], feed_id: self.id)
    query = query.or(Request.where(id: args['request_id'], feed_id: self.id)) unless args['request_id'].nil?

    # Filters
    # Filters by number range
    {
      'medias_count_min' => 'medias_count >= ?',
      'medias_count_max' => 'medias_count <= ?',
      'requests_count_min' => 'requests_count >= ?',
      'requests_count_max' => 'requests_count <= ?'
    }.each do |key, condition|
      query = query.where(condition, args[key].to_i) unless args[key].blank?
    end
    # Filters by "Fact-checked by"
    query = query.where('requests.fact_checked_by_count > 0') if args['fact_checked_by'].to_s == 'ANY'
    query = query.where('requests.fact_checked_by_count' => 0) if args['fact_checked_by'].to_s == 'NONE'
    # Other filters
    query = query.where('requests.last_submitted_at' => Range.new(*format_times_search_range_filter(JSON.parse(args['request_created_at']), nil))) unless args['request_created_at'].blank?
    query = query.where('requests.content ILIKE ?', "%#{args['keyword']}%") unless args['keyword'].blank?

    # Sort
    sort = {
      'requests' => 'requests_count',
      'medias' => 'medias_count',
      'last_submitted' => 'last_submitted_at',
      'subscriptions' => 'subscriptions_count',
      'media_type' => 'medias.type',
      'fact_checked_by' => 'fact_checked_by_count',
      'fact_checks' => 'project_medias_count'
    }[args['sort'].to_s] || 'last_submitted_at'
    sort_type = args['sort_type'].to_s.downcase == 'asc' ? 'ASC' : 'DESC'
    query = query.joins(:media) if sort == 'medias.type'

    query.order(sort => sort_type).offset(args['offset'].to_i)
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
    request.attach_to_similar_request!
    unless result_ids.blank?
      result_ids.each { |id| ProjectMediaRequest.create!(project_media_id: id, request_id: request.id, skip_check_ability: true) }
    end
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

  private

  def set_user
    self.user ||= User.current
  end

  def licenses_in_allowed_values
    unless (self.licenses - LICENSES.keys).empty?
      errors.add(:licenses, I18n.t(:"errors.messages.invalid_feed_licenses_value"))
    end
  end
end
