class User < ActiveRecord::Base
  attr_accessible :email, :login, :name, :profile_image, :password, :password_confirmation, :image
  attr_accessor :url

  has_one :source
  has_many :team_users
  has_many :teams, through: :team_users
  has_many :projects

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:twitter, :facebook, :slack]

  after_create :set_image, :create_source_and_account, :send_welcome_email
  before_save :set_token, :set_login, :set_uuid

  mount_uploader :image, ImageUploader
  validates :image, size: true
  validate :user_is_member_in_current_team

  ROLES = %w[contributor journalist editor owner admin]
  def role?(base_role, context_team)
    ROLES.index(base_role.to_s) <= ROLES.index(self.role(context_team)) unless self.role(context_team).nil?
  end

  def role(context_team)
    context_team = self.current_team if context_team.nil?
    tu = TeamUser.where(team_id: context_team.id, user_id: self.id, status: 'member').last unless context_team.nil?
    user_role = tu.nil? ? nil : tu.role.to_s
  end

  def self.from_omniauth(auth)
    token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
    user = User.where(provider: auth.provider, uuid: auth.uid).first || User.new
    user.email = auth.info.email
    user.password ||= Devise.friendly_token[0,20]
    user.name = auth.info.name
    user.uuid = auth.uid
    user.provider = auth.provider
    user.profile_image = auth.info.image
    user.token = token
    user.url = auth.url
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
      dbid: self.id,
      name: self.name,
      email: self.email,
      login: self.login,
      uuid: self.uuid,
      provider: self.provider,
      token: self.token,
      current_team: self.current_team,
      teams: self.user_teams
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
      self.teams.first
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

  private

  def create_source_and_account
    source = Source.new
    source.user = self
    source.name = self.name
    source.avatar = self.profile_image
    source.slogan = self.name
    source.save!

    if !self.provider.blank? && !self.url.blank?
      account = Account.new
      account.user = self
      account.source = source
      account.url = self.url
      account.save!
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
      tu = TeamUser.where(user_id: self.id, team_id: self.current_team_id).last
      errors.add(:base, "User not a member in team #{self.current_team_id}") if tu.nil?
    end
  end

end
