class User < ActiveRecord::Base
  self.inheritance_column = :type
  attr_accessor :url, :skip_confirmation_mail

  include ValidationsHelper
  include UserPrivate

  belongs_to :source
  has_many :team_users, dependent: :destroy
  has_many :teams, through: :team_users
  has_many :projects
  has_many :accounts

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:twitter, :facebook, :slack]

  before_create :skip_confirmation_for_non_email_provider
  after_create :set_image, :create_source_and_account
  before_save :set_token, :set_login, :set_uuid
  after_update :set_blank_email_for_unconfirmed_user
  after_create :send_welcome_email, on: :create

  mount_uploader :image, ImageUploader
  validates :image, size: true
  validate :user_is_member_in_current_team
  validate :validate_duplicate_email
  validate :languages_format, unless: proc { |u| u.settings.nil? }
  validates :api_key_id, absence: true, if: proc { |u| u.type.nil? }

  serialize :omniauth_info
  serialize :cached_teams, Array

  check_settings

  include DeviseAsync

  ROLES = %w[contributor journalist editor owner]
  def role?(base_role)
    ROLES.index(base_role.to_s) <= ROLES.index(self.role) unless self.role.nil?
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

  def self.from_omniauth(auth)
    # Update uuid for facebook account if match email and provider
    self.update_facebook_uuid(auth) if auth.provider == 'facebook'
    token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
    user = User.where(provider: auth.provider, uuid: auth.uid).first || User.new
    user.email = user.email.presence || auth.info.email
    user.password ||= Devise.friendly_token[0,20]
    user.name = auth.info.name
    user.uuid = auth.uid
    user.provider = auth.provider
    user.profile_image = auth.info.image.gsub(/^http:/, 'https:')
    user.token = token
    user.url = auth.url
    user.login = auth.info.nickname || auth.info.name.tr(' ', '-').downcase
    user.omniauth_info = auth.as_json
    User.current = user
    user.save!
    user.reload
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

  def self.update_facebook_uuid(auth)
    unless auth.info.email.blank?
      fb_user = User.where(provider: auth.provider, email: auth.info.email).first
      if !fb_user.nil? && fb_user.uuid != auth.uid
        fb_user.uuid = auth.uid
        fb_user.skip_check_ability = true
        fb_user.save!
        fb_user.update_account(auth.url)
      end
    end
  end

  def update_account(url)
    account = self.accounts.first
    if account && account.url != url
      account.url = url
      account.save
    end
  end

  def as_json(_options = {})
    {
      id: Base64.encode64("User/#{self.id}"),
      dbid: self.id,
      name: self.name,
      email: self.email,
      login: self.login,
      uuid: self.uuid,
      provider: self.provider,
      token: self.token,
      current_team: self.current_team,
      current_project: self.current_project,
      teams: self.user_teams,
      team_ids: self.team_ids,
      permissions: self.permissions,
      profile_image: self.profile_image,
      settings: self.settings,
      source_id: self.source.id,
      is_admin: self.is_admin
    }
  end

  def email_required?
    self.provider.blank? && self.new_record?
  end

  def password_required?
    super && self.provider.blank?
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
    if self.provider.blank?
      self.email
    else
      provider = self.provider.capitalize
      if !self.omniauth_info.nil?
        if self.provider == 'slack'
          provider = self.omniauth_info.dig('extra', 'raw_info', 'url')
        else
          provider = self.omniauth_info.dig('url')
          return provider if !provider.nil?
        end
      end
      "#{self.login} at #{provider}"
    end
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

  # private
  #
  # Please add private methods to app/models/concerns/user_private.rb 

end
