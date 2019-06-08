class TeamBot < ActiveRecord::Base
  include HasImage

  EVENTS = ['create_project_media', 'update_project_media', 'create_source', 'update_source', 'update_annotation_own']
  annotation_types = DynamicAnnotation::AnnotationType.all.map(&:annotation_type) + ['comment', 'flag', 'tag', 'task', 'geolocation']
  annotation_types.each do |type|
    EVENTS << "create_annotation_#{type}"
    EVENTS << "update_annotation_#{type}"
  end
  Task.task_types.each do |type|
    EVENTS << "create_annotation_task_#{type}"
    EVENTS << "update_annotation_task_#{type}"
  end
  JSON_SCHEMA_PATH = File.join(Rails.root, 'public', 'events.json')
  JSON_SCHEMA_TEMPLATE_PATH = File.join(Rails.root, 'public', 'events-template.json')
  File.atomic_write(JSON_SCHEMA_PATH) { |file| file.write(File.read(JSON_SCHEMA_TEMPLATE_PATH).gsub('<%= TeamBot::EVENTS %>', EVENTS.to_json)) }

  has_many :team_bot_installations, dependent: :destroy
  has_many :teams, through: :team_bot_installations
  belongs_to :bot_user, dependent: :destroy
  has_one :api_key, through: :bot_user
  belongs_to :team_author, class_name: 'Team'

  # [ { event: 'event_name', graphql: 'graphql query fragment' }, ... ]
  serialize :events

  # [ { name: 'field_name', label: 'Field Name', type: 'string|boolean|number', default: 'Default Value' }, ... ]
  serialize :settings

  validates_presence_of :name, :team_author_id
  validate :name_is_unique_for_this_team
  validates_format_of :request_url, with: /\Ahttps?:\/\/[^\s]+\z/
  validate :events_is_valid
  validate :can_approve
  validates_uniqueness_of :identifier

  before_validation :format_settings
  before_validation :set_identifier, on: :create
  before_create :create_bot_user
  after_create :associate_with_team
  after_update :update_role_if_changed

  scope :not_approved, -> { where approved: false }

  def avatar
    self.public_path
  end

  def json_schema_url(field)
    URI.join(CONFIG['checkdesk_base_url'], '/' + field + '.json').to_s
  end

  def subscribed_to?(event)
    return false if self.events.blank?
    self.events.collect{ |ev| ev['event'] || ev[:event] }.map(&:to_s).include?(event.to_s)
  end

  def install_to!(team)
    TeamBotInstallation.create! team_id: team.id, team_bot_id: self.id
  end

  def uninstall_from!(team)
    installation = TeamBotInstallation.where(team_id: team.id, team_bot_id: self.id).last
    installation.destroy! unless installation.nil?
  end

  def approve!
    self.approved = true
    self.save!
  end

  def graphql_result(fragment, object, team)
    begin
      klass = object.is_annotation? ? 'Annotation' : object.class.name
      object = Annotation.find(object.id) if object.is_annotation?
      current_user = User.current
      current_team = Team.current
      User.current = self.bot_user
      Team.current = team
      query = 'query { node(id: "' + object.graphql_id + '") { ...F0 } } fragment F0 on ' + klass + ' { ' + fragment + '}'
      result = RelayOnRailsSchema.execute(query, variables: {}, context: {})
      User.current = current_user
      Team.current = current_team
      JSON.parse(result.to_json)['data']['node']
    rescue StandardError => e
      Rails.logger.error("[Bot Garden] Error performing GraphQL query: #{e.message}")
      { error: "Error performing GraphQL query" }.with_indifferent_access
    end
  end

  def call(data)
    if self.core?
      User.current = self.bot_user
      bot = BOT_NAME_TO_CLASS[self.identifier.to_sym]
      bot.run(data) unless bot.blank?
      User.current = nil
    else
      begin
        uri = URI.parse(self.request_url)
        headers = { 'Content-Type': 'application/json' }
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if self.request_url =~ /^https:/
        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = data.to_json
        http.request(request)
      rescue StandardError => e
        Rails.logger.error("[Bots] Error calling bot #{self.id}: #{e.message}")
      end
    end
  end

  def notify_about_event(event, object, team, installation)
    graphql_query = nil
    self.events.each do |ev|
      if ev['event'] == event || ev[:event] == event
        graphql_query = ev['graphql'] || ev[:graphql]
      end
    end
    graphql_data = graphql_query.blank? ? nil : self.graphql_result(graphql_query, object, team)

    data = {
      event: event,
      team: team,
      object: object,
      time: Time.now,
      data: graphql_data,
      user_id: self.bot_user.id,
      settings: installation.json_settings
    }

    self.call(data)
  end

  def installed
    !self.installation.nil?
  end

  def installations_count
    self.team_bot_installations.count
  end

  def installation
    current_team = User.current ? (Team.current || User.current.current_team) : nil
    TeamBotInstallation.where(team_id: current_team.id, team_bot_id: self.id).last unless current_team.nil?
  end

  def settings_as_json_schema
    return nil if self.settings.blank?
    properties = {}
    self.settings.each do |setting|
      s = setting.with_indifferent_access
      type = s[:type]
      default = s[:default]
      default = default.to_i if type == 'number'
      default = (default == 'true' ? true : false) if type == 'boolean'
      properties[s[:name]] = {
        type: type,
        title: s[:label],
        default: default
      }
    end
    { type: 'object', properties: properties }.to_json
  end

  # In order to avoid sending the same event to the same bot multiple times per request,
  # we create a queue of events and dedupe them at the end of the request before notifying the bots.
  def self.init_event_queue
    RequestStore.store[:bot_events] = []
  end

  # If we are in the context of a request, we enqueue the event to dedupe it later.
  # If not, we may be in a background job, where the concept of a "request" is not well-defined,
  # so we notify the bots immediately.
  def self.enqueue_event(event, team_id, object, bot = nil)
    if !RequestStore.store[:bot_events].nil?
      RequestStore.store[:bot_events] << { event: event, team_id: team_id, object: object, bot: bot }
    else
      TeamBot.notify_bots(event, team_id, object.class.to_s, object.id, bot) unless object.skip_notifications
    end
  end

  def self.trigger_events
    RequestStore.store[:bot_events].uniq{|e| [e[:event], e[:team_id], e[:object].id]}.each do |e|
      TeamBot.delay_for(1.second).notify_bots(e[:event], e[:team_id], e[:object].class.to_s, e[:object].id, e[:bot]) unless e[:object].skip_notifications
    end
    RequestStore.store[:bot_events].clear
  end

  def self.notify_bots(event, team_id, object_class, object_id, target_bot)
    object = object_class.constantize.where(id: object_id).first
    team = Team.where(id: team_id).last
    return if object.nil? || team.nil?
    team.team_bot_installations.each do |team_bot_installation|
      team_bot = team_bot_installation.team_bot
      team_bot.notify_about_event(event, object, team, team_bot_installation) if team_bot.subscribed_to?(event) && (target_bot.blank? || team_bot.id == target_bot.id)
    end
  end

  # FIXME This should go away when we merge BotUser, TeamBot, and the various Bot::XXX models.
  BOT_NAME_TO_CLASS = {
    keep: Bot::Keep,
    smooch: Bot::Smooch,
    alegre: Bot::Alegre
  }

  # FIXME Convert this to an overridden method that returns false in the base class
  # and true for derived, core bots.
  def core?
    return !BOT_NAME_TO_CLASS[self.identifier.to_sym].blank?
  end

  private

  def events_is_valid
    unless self.events.blank?
      events = []
      self.events.each do |ev|
        ev = ev.last if ev.is_a?(Array)
        event = ev['event'] || ev[:event]
        graphql = ev['graphql'] || ev[:graphql]
        events << { 'event' => event, 'graphql' => graphql }
        errors.add(:base, I18n.t(:error_team_bot_event_is_not_valid)) if !EVENTS.include?(event.to_s)
      end
      self.events = events
    end
  end

  def create_bot_user
    if self.bot_user_id.blank?
      begin
        # API key
        api_key = ApiKey.new
        api_key.skip_check_ability = true
        api_key.save!
        api_key.expire_at = api_key.expire_at.since(100.years)
        api_key.save!

        # User
        bot_user = BotUser.new
        bot_user.name = self.name
        bot_user.image = self.file
        bot_user.api_key_id = api_key.id
        bot_user.skip_check_ability = true
        bot_user.save!

        # Team user
        team_user = TeamUser.new
        team_user.role = self.role
        team_user.status = 'member'
        team_user.user_id = bot_user.id
        team_user.team_id = self.team_author_id
        team_user.skip_check_ability = true
        team_user.save!
      rescue
        message = I18n.t(:could_not_save_related_bot_data)
        errors.add(:base, message)
        raise message
      end

      self.bot_user_id = bot_user.id
    end
  end

  def name_is_unique_for_this_team
    team = Team.where(id: self.team_author_id).last
    errors.add(:base, I18n.t(:bot_name_exists_for_this_team)) if team.present? && team.team_bots.where(name: self.name).where.not(id: self.id).count > 0
  end

  def associate_with_team
    params = { team_id: self.team_author_id, team_bot_id: self.id }
    TeamBotInstallation.create!(params)
  end

  def can_approve
    if User.current.present? && !User.current.is_admin? && self.approved == true && self.approved_was == false
      errors.add(:base, I18n.t(:only_admins_can_approve_bots))
    end
  end

  def set_identifier
    if self.team_author.present? && !self.name.blank? && self.identifier.blank?
      id = ['bot', self.team_author.slug, self.name.parameterize.underscore].join('_')
      count = TeamBot.where(identifier: id).count
      id += "_#{count}" if count > 0
      self.identifier = id
    end
  end

  def update_role_if_changed
    TeamUser.where(user_id: self.bot_user_id).update_all(role: self.role) if self.role != self.role_was
  end

  def format_settings
    if self.respond_to?(:settings) && !self.settings.blank?
      settings = []
      self.settings.each do |s|
        s = s.last if s.is_a?(Array)
        s = s.with_indifferent_access
        name = s['name']
        label = s['label']
        type = s['type']
        default = s['default']
        settings << { 'name' => name, 'label' => label, 'type' => type, 'default' => default }
      end
      self.settings = settings
    end
  end
end
