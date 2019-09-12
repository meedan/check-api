class BotUser < User

  EVENTS = ['create_project_media', 'update_project_media', 'create_source', 'update_source', 'update_annotation_own']
  if ActiveRecord::Base.connection.table_exists?(:dynamic_annotation_annotation_types)
    annotation_types = DynamicAnnotation::AnnotationType.all.map(&:annotation_type) + ['comment', 'flag', 'tag', 'task', 'geolocation']
    annotation_types.each do |type|
      EVENTS << "create_annotation_#{type}"
      EVENTS << "update_annotation_#{type}"
    end
    Task.task_types.each do |type|
      EVENTS << "create_annotation_task_#{type}"
      EVENTS << "update_annotation_task_#{type}"
    end
  end
  JSON_SCHEMA_PATH = File.join(Rails.root, 'public', 'events.json')
  JSON_SCHEMA_TEMPLATE_PATH = File.join(Rails.root, 'public', 'events-template.json')
  File.atomic_write(JSON_SCHEMA_PATH) { |file| file.write(File.read(JSON_SCHEMA_TEMPLATE_PATH).gsub('<%= BotUser::EVENTS %>', EVENTS.to_json)) }

  scope :not_approved, -> { where('settings LIKE ?', '%approved: false%') }

  before_validation :set_team_author_id
  before_validation :format_settings
  before_validation :set_version
  before_validation :set_fields
  before_validation :set_identifier, on: :create
  before_validation :create_api_key, on: :create
  after_create :add_to_team
  after_update :update_role_if_changed

  validates_uniqueness_of :login
  validates :api_key_id, presence: true, uniqueness: true
  validate :request_url_format
  validate :events_is_valid
  validate :can_approve

  belongs_to :api_key, dependent: :destroy
  belongs_to :source, dependent: :destroy

  devise

  check_settings

  def identifier
    self.login
  end

  def avatar
    self.source&.image&.to_s
  end

  def team_author_id
    id = @team_author_id || self.get_team_author_id
    id.blank? ? nil : id.to_i
  end

  def team_author_id=(id)
    @team_author_id = id
    self.set_team_author_id(id)
  end

  def team_author
    Team.where(id: self.team_author_id).last
  end

  def team_bot_installations
    self.team_users.joins(:user).where('users.type' => 'BotUser', 'team_users.type' => 'TeamBotInstallation')
  end

  def email_required?
    false
  end

  def password_required?
    false
  end

  def active_for_authentication?
    false
  end

  def bot_events
    events = self.get_events
    events ? events.collect{ |e| e['event'] || e[:event] }.join(',') : ''
  end

  def is_bot
    true
  end

  def events
    self.get_events
  end

  def events=(list)
    self.set_events(list)
  end

  def json_schema_url(field)
    URI.join(CONFIG['checkdesk_base_url'], '/' + field + '.json').to_s
  end

  def subscribed_to?(event)
    return false if self.get_events.blank?
    self.get_events.collect{ |ev| ev['event'] || ev[:event] }.map(&:to_s).include?(event.to_s)
  end

  def install_to!(team)
    TeamBotInstallation.create! team_id: team.id, user_id: self.id
  end

  def uninstall_from!(team)
    installation = TeamBotInstallation.where(team_id: team.id, user_id: self.id).last
    installation.destroy! unless installation.nil?
  end

  def approve!
    self.set_approved(true)
    self.save!
  end

  def graphql_result(fragment, object, team)
    begin
      klass = object.is_annotation? ? 'Annotation' : object.class.name
      object = Annotation.find(object.id) if object.is_annotation?
      current_user = User.current
      current_team = Team.current
      User.current = User.find(self.id)
      Team.current = team
      query = 'query { node(id: "' + object.graphql_id + '") { ...F0 } } fragment F0 on ' + klass + ' { ' + fragment + '}'
      result = RelayOnRailsSchema.execute(query, variables: {}, context: {})
      User.current = current_user
      Team.current = current_team
      JSON.parse(result.to_json)['data']['node']
    rescue StandardError => e
      Rails.logger.error("[BotUser] Error performing GraphQL query: #{e.message}")
      Airbrake.notify(e) if Airbrake.configuration.api_key
      { error: "Error performing GraphQL query" }.with_indifferent_access
    end
  end

  def call(data)
    begin
      if self.core?
        User.current = self
        bot = "Bot::#{self.identifier.camelize}".constantize
        bot.run(data.with_indifferent_access) unless bot.blank?
      else
        uri = URI.parse(self.get_request_url)
        headers = { 'Content-Type': 'application/json' }
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if self.get_request_url =~ /^https:/
        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = data.to_json
        http.request(request)
      end
    rescue StandardError => e
      Rails.logger.error("[BotUser] Error calling bot #{self.identifier}: #{e.message}")
      Airbrake.notify(e) if Airbrake.configuration.api_key
      User.current = nil
    end
  end

  def notify_about_event(event, object, team, installation)
    graphql_query = nil
    self.get_events.each do |ev|
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
      user_id: self.id,
      settings: installation.json_settings
    }

    self.call(data)
  end

  def installed
    !self.installation.nil?
  end

  def installations_count
    self.team_users.count
  end

  def installation
    current_team = User.current ? (Team.current || User.current.current_team) : nil
    TeamBotInstallation.where(team_id: current_team.id, user_id: self.id).last unless current_team.nil?
  end

  def settings_ui_schema
    return nil if self.get_settings.blank?
    schema = {}
    self.get_settings.each do |setting|
      s = setting.with_indifferent_access
      schema[s[:name]] = { 'ui:widget' => 'textarea' } if s[:name] =~ /^smooch_message_/
      schema[s[:name]] = { 'ui:options' => { 'disabled' => true } } if s[:type] == 'readonly'
    end
    schema.to_json
  end

  def settings_as_json_schema(validate = false)
    return nil if self.get_settings.blank?
    properties = {}
    self.get_settings.each do |setting|
      s = setting.with_indifferent_access
      type = s[:type]
      next if type == 'hidden'
      default = s[:default]
      default = default.to_i if type == 'number'
      default = (default == 'true' ? true : false) if type == 'boolean'
      properties[s[:name]] = {
        type: type,
        title: s[:label],
        default: default
      }
      properties[s[:name]][:enum] = Team.current&.team_tasks.to_a.collect{ |t| { key: t.id, value: t.label } } if !validate && s[:name] == 'smooch_task'
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
      BotUser.notify_bots(event, team_id, object.class.to_s, object.id, bot) unless object.skip_notifications
    end
  end

  def self.trigger_events
    RequestStore.store[:bot_events].uniq{|e| [e[:event], e[:team_id], e[:object].id]}.each do |e|
      BotUser.delay_for(1.second).notify_bots(e[:event], e[:team_id], e[:object].class.to_s, e[:object].id, e[:bot]) unless e[:object].skip_notifications
    end
    RequestStore.store[:bot_events].clear
  end

  def self.notify_bots(event, team_id, object_class, object_id, target_bot)
    object = object_class.constantize.where(id: object_id).first
    team = Team.where(id: team_id).last
    return if object.nil? || team.nil?
    team.team_bot_installations.each do |team_bot_installation|
      bot = team_bot_installation.bot_user
      bot.notify_about_event(event, object, team, team_bot_installation) if bot.subscribed_to?(event) && (target_bot.blank? || bot.id == target_bot.id)
    end
  end

  def core?
    begin Module.const_defined?("Bot::#{self.identifier.camelize}") rescue false end
  end

  protected

  def confirmation_required?
    false
  end

  private

  def set_fields
    self.email = self.password = self.password_confirmation = nil
    self.is_admin = false
    true
  end

  def request_url_format
    errors.add(:base, I18n.t(:bot_request_url_invalid)) if !self.get_request_url.blank? && self.get_request_url.to_s.match(/\Ahttps?:\/\/[^\s]+\z/).nil?
  end

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

  def can_approve
    approved = self.settings.to_h.with_indifferent_access[:approved]
    approved_was = self.settings_was.to_h.with_indifferent_access[:approved]
    if User.current.present? && !User.current.is_admin? && approved == true && approved_was != true
      errors.add(:base, I18n.t(:only_admins_can_approve_bots))
    end
  end

  def format_settings
    return if self.get_settings.is_a?(Hash)
    if !self.get_settings.blank?
      settings = []
      self.get_settings.each do |s|
        s = s.last if s.is_a?(Array)
        s = s.with_indifferent_access
        name = s['name']
        label = s['label']
        type = s['type']
        default = s['default']
        settings << { 'name' => name, 'label' => label, 'type' => type, 'default' => default }
      end
      self.set_settings(settings)
    end
  end

  def set_identifier
    if !self.name.blank? && self.identifier.blank?
      id = ['bot', self.name.parameterize.underscore].join('_')
      count = BotUser.where(login: id).count
      id += "_#{count}" if count > 0
      self.login = id
    end
  end

  def create_api_key
    if self.api_key_id.blank?
      api_key = ApiKey.new
      api_key.skip_check_ability = true
      api_key.save!
      api_key.expire_at = api_key.expire_at.since(100.years)
      api_key.save!
      self.api_key_id = api_key.id
    end
  end

  def add_to_team
    if self.team_author_id
      team_user = TeamUser.new
      team_user.type = 'TeamBotInstallation'
      team_user.role = self.get_role || 'contributor'
      team_user.status = 'member'
      team_user.user_id = self.id
      team_user.team_id = self.team_author_id || Team.current.id
      team_user.skip_check_ability = true
      team_user.save!
    end
  end

  def update_role_if_changed
    TeamBotInstallation.where(user_id: self.id).update_all(role: self.get_role) if self.settings_changed?
  end

  def set_version
    self.set_version('0.0.1') if self.get_version.blank?
  end

  def set_team_author_id
    self.team_author_id = Team.current&.id if self.team_author_id.blank?
  end
end
