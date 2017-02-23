class User < ActiveRecord::Base
  attr_accessor :url

  has_one :source
  has_many :team_users
  has_many :teams, through: :team_users
  has_many :projects
  has_many :accounts

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:twitter, :facebook, :slack]

  after_create :set_image, :create_source_and_account, :send_welcome_email
  before_save :set_token, :set_login, :set_uuid

  mount_uploader :image, ImageUploader
  validates :image, size: true
  validate :user_is_member_in_current_team
  validate :validate_duplicate_email, on: :create

  serialize :omniauth_info

  include CheckdeskSettings

  ROLES = %w[contributor journalist editor owner]
  def role?(base_role)
    ROLES.index(base_role.to_s) <= ROLES.index(self.role) unless self.role.nil?
  end

  def role
    context_team = Team.current || self.current_team
    role = nil
    unless context_team.nil?
      role = Rails.cache.fetch("role_#{context_team.id}_#{self.id}", expires_in: 30.seconds) do
        tu = TeamUser.where(team_id: context_team.id, user_id: self.id, status: 'member').last
        tu.nil? ? nil : tu.role.to_s
      end
    end
    role
  end

  def self.from_omniauth(auth)
    token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
    user = User.where(provider: auth.provider, uuid: auth.uid).first || User.new
    user.email = user.email.presence || auth.info.email
    user.password ||= Devise.friendly_token[0,20]
    user.name = auth.info.name
    user.uuid = auth.uid
    user.provider = auth.provider
    user.profile_image = auth.info.image
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
      teams: self.user_teams,
      team_ids: self.team_ids,
      permissions: self.permissions,
      profile_image: self.profile_image
    }
  end

  def email_required?
    self.provider.blank?
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

  def user_teams
    team_users = TeamUser.where(user_id: self.id)
    teams = Hash.new
    team_users.each do |tu|
      teams[tu.team.name] = tu.as_json
    end
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
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  def set_password=(value)
    return nil if value.blank?
    self.password = value
    self.password_confirmation = value
  end

  protected

  def confirmation_required?
    self.provider.blank?
  end

  private

  def create_source_and_account
    source = Source.new
    source.user = self
    source.name = self.name
    source.avatar = self.profile_image
    source.slogan = self.name
    source.save!

    if !self.provider.blank? && !self.url.blank?
      begin
        account = Account.new
        account.user = self
        account.source = source
        account.url = self.url
        account.save
      rescue Errno::ECONNREFUSED => e
        Rails.logger.info "Could not create account for user ##{self.id}: #{e.message}"
      end
    end
  end

  def set_token
    self.token = User.token('checkdesk', self.id, Devise.friendly_token[0, 8], Devise.friendly_token[0, 8]) if self.token.blank?
  end

  def set_login
    if self.login.blank?
      if self.email.blank?
        self.login = self.name.tr(' ', '-').downcase
      else
        self.login = self.email.split('@')[0]
      end
    end
  end

  def set_uuid
    self.uuid = ('checkdesk_' + Digest::MD5.hexdigest(self.email)) if self.uuid.blank?
  end

  def send_welcome_email
    RegistrationMailer.welcome_email(self).deliver_now if self.provider.blank? && CONFIG['send_welcome_email_on_registration']
  end

  def set_image
    if self.profile_image.blank?
      self.profile_image = CONFIG['checkdesk_base_url'] + User.find(self.id).image.url
      self.save!
    end
  end

  def user_is_member_in_current_team
    unless self.current_team_id.blank?
      tu = TeamUser.where(user_id: self.id, team_id: self.current_team_id, status: 'member').last
      errors.add(:base, "User not a member in team #{self.current_team_id}") if tu.nil?
    end
  end

  def validate_duplicate_email
    u = User.where(email: self.email).last
    unless u.nil?
      RegistrationMailer.duplicate_email_detection(self, u).deliver_now
      errors.add(:base, "This email already exists")
    end
  end

end
