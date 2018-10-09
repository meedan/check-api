class User < ActiveRecord::Base
  self.inheritance_column = :type
  attr_accessor :url, :skip_confirmation_mail, :invitation_role

  include ValidationsHelper
  include UserPrivate

  belongs_to :source
  has_many :team_users, dependent: :destroy
  has_many :teams, through: :team_users
  has_many :projects
  has_many :accounts
  belongs_to :account

  devise :database_authenticatable, :registerable, :invitable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:twitter, :facebook, :slack]

  before_create :skip_confirmation_for_non_email_provider
  after_create :create_source_and_account, :set_source_image, :send_welcome_email
  before_save :set_token, :set_login, :set_uuid
  after_update :set_blank_email_for_unconfirmed_user
  before_destroy :can_destroy_user, prepend: true
  after_invitation_created :set_team_user_invitation

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

  # has_many :invitations, :class_name => self.to_s, :as => :invited_by


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
    user.token = token
    user.url = auth.url
    user.login = auth.info.nickname || auth.info.name.tr(' ', '-').downcase
    user.omniauth_info = auth.as_json
    User.current = user
    user.save!
    user.set_source_image
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

  def set_source_image
    return if self.source.nil?
    if !self.image.nil? && self.image.url != '/images/user.png'
      self.source.file = self.image
      self.source.save
    end
    image = self.omniauth_info.dig('info', 'image') if self.omniauth_info
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
    [:name, :email, :login, :uuid, :provider, :token, :current_team, :current_project, :team_ids, :permissions, :profile_image, :settings, :is_admin, :accepted_terms, :last_accepted_terms_at].each do |field|
      user[field] = self.send(field)
    end
    user
  end

  def email_required?
    self.provider.blank? && self.new_record?
  end

  def password_required?
    super && self.provider.blank?
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

  def self.send_user_invitation(members, text=nil)
    msg = {}
    members.each do |role, emails|
      emails.split(',').each do |email|
        u = User.where(email: email).last
        begin
          if u.nil?
            User.invite!({:email => email, :name => email.split("@").first, :invitation_role => role}, User.current)
            msg[email] = 'success'
          else
            u.invitation_role = role
            msg.merge!(u.set_team_user_invitation)
          end
        rescue StandardError => e
          msg[email] = e.message
        end
      end
    end
    msg
  end

  def self.accept_team_invitation(token, slug)
    user = User.find_by_invitation_token(token, true)
    User.accept_invitation!(:invitation_token => token, :password => "dummypassword") unless user.nil?
    t = Team.where(slug: slug).last
    unless t.nil?
      invitation_token = Devise.token_generator.digest(self, :invitation_token, token)
      tu = TeamUser.where(team_id: t.id, status: 'invited', invitation_token: invitation_token).last
      unless tu.nil?
        tu.invitation_accepted_at = Time.now.utc
        tu.invitation_token = nil
        tu.status = 'member'
        tu.save!
      end
    end
  end

  def set_team_user_invitation
    msg = {}
    unless Team.current.nil?
      tu = TeamUser.where(team_id: Team.current.id, user_id: self.id).last
      if tu.nil?
        raw, enc = Devise.token_generator.generate(User, :invitation_token) if self.invitation_token.nil?
        tu = TeamUser.new
        tu.user_id = self.id
        tu.team_id = Team.current.id
        tu.role = self.invitation_role
        tu.status = 'invited'
        tu.invited_by_id = self.invited_by_id
        tu.invited_by_id ||= User.current.id unless User.current.nil?
        tu.invitation_token = self.invitation_token || enc
        if tu.save!
          msg[self.email] = 'success'
          # send invitation email
          self.send_invitation_mail(raw)
        end
      elsif tu.status == 'invited'
        tu.invitation_token = self.invitation_token; tu.save!
        msg[self.email] = 'This email already invited to this team'
      else
        msg[self.email] = 'This email already a team member'
      end
    end
    msg
  end

  def send_invitation_mail(token)
    self.invited_by = User.current
    DeviseMailer.delay.invitation_instructions(self, token, opts={})
  end

  # private
  #
  # Please add private methods to app/models/concerns/user_private.rb
end
