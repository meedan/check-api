class User < ActiveRecord::Base
  self.inheritance_column = :type
  attr_accessor :skip_confirmation_mail, :from_omniauth_login

  include ValidationsHelper
  include UserPrivate
  include UserInvitation
  include UserMultiAuthLogin

  belongs_to :source
  has_many :team_users, dependent: :destroy
  has_many :teams, through: :team_users
  has_many :projects
  has_many :accounts
  has_many :assignments, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:twitter, :facebook, :slack]

  before_create :skip_confirmation_for_non_email_provider
  after_create :create_source_and_account, :set_source_image, :send_welcome_email
  before_save :set_token, :set_login
  after_update :set_blank_email_for_unconfirmed_user
  before_destroy :can_destroy_user, prepend: true

  mount_uploader :image, ImageUploader
  validates :image, size: true
  validate :user_is_member_in_current_team
  validate :validate_duplicate_email
  validate :languages_format, unless: proc { |u| u.settings.nil? }
  validates :api_key_id, absence: true, if: proc { |u| u.type.nil? }
  validates_presence_of :name

  serialize :cached_teams, Array

  check_settings

  include DeviseAsync

  ROLES = %w[contributor journalist editor owner]

  def role?(base_role)
    role = self.role
    return true if role.to_s == base_role.to_s
    return false if !ROLES.include?(base_role.to_s) || !ROLES.include?(role.to_s)
    ROLES.index(base_role.to_s) <= ROLES.index(role) unless role.nil?
  end

  def role(team = nil)
    context_team = team || Team.current || self.current_team
    return nil if context_team.nil?
    @roles ||= {}
    if @roles[context_team.id].nil?
      tu = TeamUser.where(team_id: context_team.id, user_id: self.id, status: 'member').last
      @roles[context_team.id] = tu.nil? ? nil : tu.role.to_s
    end
    @roles[context_team.id]
  end

  def number_of_teams
    self.cached_teams.size
  end

  def teams_owned
    self.teams.joins(:team_users).where({'team_users.role': 'owner', 'team_users.status': 'member'})
  end

  def assign_annotation(annotation)
    Assignment.create! user_id: self.id, assigned_id: annotation.id, assigned_type: 'Annotation'
  end

  def self.token(provider, id, token, secret)
    Base64.encode64({
      provider: provider.to_s,
      id: id.to_s,
      token: token.to_s,
      secret: secret.to_s
    }.to_json).gsub("\n", '++n')
  end

  def self.from_token(token)
    JSON.parse(Base64.decode64(token.gsub('++n', "\n")))
  end

  def set_source_image
    source = self.source
    unless source.nil?
      if !self.image.nil? && self.image.url != '/images/user.png'
        source.file = self.image
        source.save
      end
      set_source_avatar
    end
  end

  def set_source_avatar
    a = self.get_social_accounts_for_login
    a = a.first unless a.nil?
    image = a.omniauth_info.dig('info', 'image') if !a.nil? && !a.omniauth_info.nil?
    avatar = image ? image.gsub(/^http:/, 'https:') : CONFIG['checkdesk_base_url'] + self.image.url
    self.source.set_avatar(avatar)
  end

  def update_account(url)
    account = self.accounts.first
    if account && account.url != url
      account.url = url
      account.save
    end
  end

  def as_json(_options = {})
    user = {
      id: Base64.encode64("User/#{self.id}"),
      dbid: self.id,
      teams: self.user_teams,
      source_id: self.source.id
    }
    [:name, :email, :login, :token, :current_team, :current_project, :team_ids, :permissions, :profile_image, :settings, :is_admin, :accepted_terms, :last_accepted_terms_at].each do |field|
      user[field] = self.send(field)
    end
    user
  end

  def email_required?
    !self.from_omniauth_login && self.new_record?
  end

  def password_required?
    super && !self.from_omniauth_login
  end

  def inactive_message
    self.is_active? ? super :  I18n.t(:banned_user, app_name: CONFIG['app_name'], support_email: CONFIG['support_email'])
  end

  def active_for_authentication?
    super && self.is_active?
  end

  def current_team
    if self.current_team_id.blank?
      tu = TeamUser.where(user_id: self.id, status: 'member').last
      tu.team unless tu.nil?
    else
      Team.where(id: self.current_team_id).last
    end
  end

  def current_project
    Project.where(id: self.current_project_id).last unless self.current_project_id.blank?
  end

  def user_teams
    team_users = TeamUser.where(user_id: self.id)
    teams = Hash.new
    team_users.each{ |tu| teams[tu.team.slug] = tu.as_json }
    teams.to_json
  end

  def is_member_of?(team)
    !self.team_users.select{ |tu| tu.team_id == team.id && tu.status == 'member' }.empty?
  end

  def handle
    self.email.blank? ? get_provider_from_user_account : self.email
  end

  def get_provider_from_user_account
    account = self.get_social_accounts_for_login
    account = account.first unless account.nil?
    return nil if account.nil?
    provider = account.provider.capitalize
    if !account.omniauth_info.nil?
      if account.provider == 'slack'
        provider = account.omniauth_info.dig('extra', 'raw_info', 'url')
      else
        provider = account.omniauth_info.dig('url')
        return provider if !provider.nil?
      end
    end
    "#{self.login} at #{provider}"
  end

  # Whether two users are members of any same team
  def is_a_colleague_of?(user)
    results = TeamUser.find_by_sql(['SELECT COUNT(*) AS count FROM team_users tu1 INNER JOIN team_users tu2 ON tu1.team_id = tu2.team_id WHERE tu1.user_id = :user1 AND tu2.user_id = :user2 AND tu1.status = :status AND tu2.status = :status', { user1: self.id, user2: user.id, status: 'member' }])
    results.first.count.to_i >= 1
  end

  def self.current
    RequestStore.store[:user]
  end

  def self.current=(user)
    RequestStore.store[:user] = user
  end

  def set_password=(value)
    return nil if value.blank?
    self.password = value
    self.password_confirmation = value
  end

  def annotations(*types)
    list = Annotation.where(annotator_type: 'User', annotator_id: self.id.to_s)
    list = list.where(annotation_type: types) unless types.empty?
    list.order('id DESC')
  end

  def jsonsettings
    self.settings.to_json
  end

  def languages=(languages)
    self.send(:set_languages, languages)
  end

  def is_confirmed?
    self.confirmed? && self.unconfirmed_email.nil?
  end

  def send_email_notifications=(enabled)
    enabled = enabled == "1" ? true : false if enabled.class.name == "String"
    self.send(:set_send_email_notifications, enabled)
  end

  def profile_image
    self.source.nil? ? nil : self.source.avatar
  end

  def bot_events
    ''
  end

  def is_bot
    false
  end

  def accept_terms=(accept)
    if accept
      self.last_accepted_terms_at = Time.now
      self.save!
    end
  end

  def accepted_terms
    self.last_accepted_terms_at.to_i >= User.terms_last_updated_at
  end

  def self.terms_last_updated_at_by_page(page)
    mapping = {
      tos: 'tos_url',
      privacy_policy: 'privacy_policy_url'
    }.with_indifferent_access
    return 0 unless mapping.has_key?(page)
    Time.parse(open(CONFIG[mapping[page]]).read.gsub(/\R+/, ' ').gsub(/.*Last modified: ([^<]+).*/, '\1')).to_i
  end

  def self.terms_last_updated_at
    require 'open-uri'
    begin
      tos = User.terms_last_updated_at_by_page(:tos)
      pp = User.terms_last_updated_at_by_page(:privacy_policy)
      tos > pp ? tos : pp
    rescue
      e = StandardError.new('Could not read the last time that terms of service or privacy policy were updated')
      Airbrake.notify(e) if Airbrake.configuration.api_key
      0
    end
  end

  def self.delete_check_user(user)
    begin
      rand_id = Time.now.to_i
      s = user.source
      columns = {
        name: "Anonymous", login: "Anonymous", token: "#{user.token}-#{rand_id}",
        email: nil, source_id: nil, is_active: false
      }
      user.update_columns(columns)
      # delete source profile and accounts
      self.delete_user_profile(s) unless s.nil?
      # update team user status
      TeamUser.where(user_id: user.id).update_all(status: 'banned')
    rescue StandardError => e
      raise e.message
    end
    # notify team(s) owner & privacy
    user.teams.each do |team|
      DeleteUserMailer.delay.notify_owners(user, team)
    end
    DeleteUserMailer.delay.notify_privacy(user) unless CONFIG['privacy_email'].blank?
  end

  def self.set_assignments_progress(user_id, project_media_id)
    required_tasks_count = 0
    answered_tasks_count = 0
    Task.where(annotated_type: 'ProjectMedia', annotated_id: project_media_id).each do |task|
      task = task.reload
      if task.required_for_user(user_id)
        required_tasks_count += 1
        answered_tasks_count += 1 if task.responses.select{ |r| r.annotator_id.to_i == user_id }.any?
      end
    end
    Rails.cache.write("cache-assignments-progress-#{user_id}-project-media-#{project_media_id}", {
      answered: answered_tasks_count,
      total: required_tasks_count,
    })
  end

  def self.delete_user_profile(s)
    current_user = User.current
    User.current = nil
    accounts_id = s.accounts.map(&:id)
    AccountSource.where(source_id: s.id).each{|as| as.skip_check_ability = true; as.destroy;}
    accounts_id.each do |id|
      as_count = AccountSource.where(account_id: id).count
      if as_count == 0
        a = Account.where(id: id).last
        a.skip_check_ability = true
        a.destroy unless a.nil?
      end
    end
    s.annotations.map(&:destroy)
    s.skip_check_ability = true
    s.destroy
    User.current = current_user
  end

  # private
  #
  # Please add private methods to app/models/concerns/user_private.rb
end
