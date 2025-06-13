class Feed < ApplicationRecord
  include SearchHelper

  check_settings

  has_many :requests
  has_many :feed_teams, dependent: :restrict_with_error
  has_many :teams, through: :feed_teams
  has_many :feed_invitations, dependent: :destroy
  has_many :clusters
  belongs_to :user, optional: true
  belongs_to :media_saved_search, -> { where(list_type: 'media') }, class_name: 'SavedSearch', optional: true
  belongs_to :article_saved_search, -> { where(list_type: 'article') }, class_name: 'SavedSearch', optional: true
  belongs_to :team, optional: true

  before_validation :set_user_and_team, :set_uuid, on: :create
  validates_presence_of :name
  validates_presence_of :licenses, if: proc { |feed| feed.discoverable }
  validate :saved_search_belongs_to_feed_teams
  validate :validate_saved_search_types

  after_create :create_feed_team
  before_destroy :destroy_feed_team, prepend: true

  PROHIBITED_FILTERS = ['team_id', 'feed_id', 'clusterize']
  LICENSES = { 1 => 'academic', 2 => 'commercial', 3 => 'open_source' }
  validates_inclusion_of :licenses, in: LICENSES.keys, if: proc { |feed| feed.discoverable }
  DATA_POINTS = { 1 => 'articles', 2 => 'media_claim_requests', 3 => 'tags' }
  validates_inclusion_of :data_points, in: DATA_POINTS.keys

  # Filters for the whole feed: applies to all data from all teams
  def get_feed_filters(view = :fact_check) # "view" can be :fact_check or :media
    filters = {}
    if view.to_sym == :fact_check && self.published && self.data_points.to_a.include?(1)
      filters.merge!({ 'report_status' => ['published'] })
    elsif view.to_sym == :media && self.published && self.data_points.to_a.include?(2)
      filters.merge!({}) # Show everything
    else
      filters.merge!({ 'report_status' => ['none'] }) # Invalidate the query
    end
    filters
  end

  def filters
    {}
  end

  # Filters defined by each team
  def get_team_filters(feed_team_ids = nil)
    filters = []
    conditions = { shared: true }
    conditions[:team_id] = feed_team_ids if feed_team_ids.is_a?(Array)
    self.feed_teams.where(conditions).find_each do |ft|
      media_saved_search = self.team_id == ft.team_id ? self.media_saved_search : ft.media_saved_search
      if media_saved_search.blank? # Do not share anything from this team if they haven't chosen a list yet
        filters << { 'team_id' => ft.team_id, 'report_status' => ['none'] }
      else
        filters << media_saved_search.filters.to_h.reject{ |k, _v| PROHIBITED_FILTERS.include?(k.to_s) }.merge({ 'team_id' => ft.team_id })
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

  def get_team_ids
    team_ids = self.feed_teams.map(&:team_id)
    team_ids << self.team_id
    team_ids.uniq
  end

  def item_belongs_to_feed?(pm)
    items = self.project_media_ids(pm.team_id)
    items.include?(pm.id)
  end

  def search(args = {})
    query = Request.where(request_id: args[:request_id], feed_id: self.id)
    query = query.or(Request.where(id: args[:request_id], feed_id: self.id)) unless args[:request_id].nil?

    # Filters
    # Filters by number range
    {
      medias_count_min: 'medias_count >= ?',
      medias_count_max: 'medias_count <= ?',
      requests_count_min: 'requests_count >= ?',
      requests_count_max: 'requests_count <= ?'
    }.each do |key, condition|
      query = query.where(condition, args[key].to_i) unless args[key].blank?
    end
    # Filters by "Fact-checked by"
    query = query.where('requests.fact_checked_by_count > 0') if args[:fact_checked_by].to_s == 'ANY'
    query = query.where('requests.fact_checked_by_count' => 0) if args[:fact_checked_by].to_s == 'NONE'
    # Other filters
    query = query.where('requests.last_submitted_at' => Range.new(*format_times_search_range_filter(JSON.parse(args[:request_created_at]), nil))) unless args[:request_created_at].blank?
    query = query.where('requests.content ILIKE ?', "%#{args[:keyword]}%") unless args[:keyword].blank?

    # Sort
    sort = {
      requests: 'requests_count',
      medias: 'medias_count',
      last_submitted: 'last_submitted_at',
      subscriptions: 'subscriptions_count',
      media_type: 'medias.type',
      fact_checked_by: 'fact_checked_by_count',
      fact_checks: 'project_medias_count'
    }[args[:sort].to_s] || :last_submitted_at
    sort_type = args[:sort_type].to_s.downcase == 'asc' ? 'ASC' : 'DESC'
    query = query.joins(:media) if sort == 'medias.type'

    query.order(sort => sort_type).offset(args[:offset].to_i)
  end

  def clusters_count(args = {})
    self.filtered_clusters(args).count
  end

  def filtered_clusters(args = {})
    team_ids = args[:team_ids]
    channels = args[:channels]
    query = self.clusters.joins(:project_media)

    # Filter by workspace
    diff = self.team_ids - team_ids.to_a.map(&:to_i)
    query = query.where.not("ARRAY[?] && team_ids", diff) unless team_ids.blank? || diff.empty?
    query = query.where(team_ids: []) if team_ids&.empty? # Invalidate the query

    # Filter by channel
    query = query.where("ARRAY[?] && channels", channels.to_a.map(&:to_i)) unless channels.blank?

    # Filter by media type
    query = query.joins(project_media: :media).where('medias.type' => args[:media_type]) unless args[:media_type].blank?

    # Filter by date
    query = query.where(last_request_date: Range.new(*format_times_search_range_filter(JSON.parse(args[:last_request_date]), nil))) unless args[:last_request_date].blank?

    # Filters by number range
    {
      medias_count_min: 'media_count >= ?',
      medias_count_max: 'media_count <= ?',
      requests_count_min: 'requests_count >= ?',
      requests_count_max: 'requests_count <= ?'
    }.each do |key, condition|
      query = query.where(condition, args[key].to_i) unless args[key].blank?
    end

    query
  end

  def media_saved_search_was
    SavedSearch.find_by_id(self.media_saved_search_id_before_last_save)
  end

  def article_saved_search_was
    SavedSearch.find_by_id(self.article_saved_search_id_before_last_save)
  end

  def get_exported_data(filters)
    data = [['Title', 'Description', 'Date (first)', 'Date (last)', 'Number of media', 'Number of requests', 'Number of fact-checks', 'Cluster URL', 'Workspaces', 'Ratings']]
    self.filtered_clusters(filters).find_each do |cluster|
      description = cluster.center.description.blank? ? cluster.center.extracted_text : cluster.center.description
      data << [cluster.title, description, cluster.first_item_at, cluster.last_item_at, cluster.media_count, cluster.requests_count, cluster.fact_checks_count, cluster.full_url, cluster.team_names.join("\n"), cluster.ratings.join("\n")]
    end
    data
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
    return if pm.blank?
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

  def set_user_and_team
    self.user ||= User.current
    self.team ||= Team.current
  end

  def saved_search_belongs_to_feed_teams
    [media_saved_search, article_saved_search].each do |saved_search|
      next if saved_search.blank?

      unless self.get_team_ids.include?(saved_search.team_id)
        errors.add("#{saved_search.list_type}_saved_search_id".to_sym, I18n.t(:"errors.messages.invalid_feed_saved_search_value"))
      end
    end
  end

  def validate_saved_search_types
    if media_saved_search.present? && media_saved_search.list_type != 'media'
      errors.add(:media_saved_search, I18n.t(:"errors.messages.invalid_feed_saved_search_list_type"))
    end

    if article_saved_search.present? && article_saved_search.list_type != 'article'
      errors.add(:article_saved_search, I18n.t(:"errors.messages.invalid_feed_saved_search_list_type"))
    end
  end

  def create_feed_team
    unless self.team.nil?
      feed_team = FeedTeam.new(feed: self, team: self.team, shared: true)
      feed_team.skip_check_ability = true
      feed_team.save!
    end
  end

  def destroy_feed_team
    FeedTeam.where(feed: self, team: self.team).last.destroy!
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
