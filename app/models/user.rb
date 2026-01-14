require 'open-uri'

class User < ApplicationRecord
  class ToSOrPrivacyPolicyReadError < StandardError; end

  self.inheritance_column = :type
  attr_accessor :skip_confirmation_mail, :from_omniauth_login, :frozen_account_ids, :frozen_source_id

  include ValidationsHelper
  include UserPrivate
  include UserInvitation
  include UserMultiAuthLogin
  include UserTwoFactorAuth

  belongs_to :source, optional: true
  has_many :team_users, dependent: :destroy
  has_many :teams, through: :team_users
  has_many :accounts, inverse_of: :user
  has_many :assignments, dependent: :destroy
  has_many :medias
  has_many :project_medias
  has_many :sources
  has_many :login_activities
  has_many :project_media_users, dependent: :destroy
  has_many :claim_descriptions
  has_many :fact_checks
  has_many :feeds
  has_many :feed_invitations
  has_many :tipline_requests
  has_many :api_keys
  has_many :explainers

  devise :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:twitter, :facebook, :slack, :google_oauth2]

  before_create :skip_confirmation_for_non_email_provider, :set_last_received_terms_email_at
  after_create :create_source_and_account, :set_source_image, :send_welcome_email
  before_save :set_token, :set_login
  after_update :set_blank_email_for_unconfirmed_user
  before_destroy :freeze_account_ids_and_source_id
  before_destroy :can_destroy_user, prepend: true

  mount_uploader :image, ImageUploader
  validates :image, size: true
  validate :user_is_member_in_current_team, :validate_duplicate_email, :password_complexity
  validate :languages_format, unless: proc { |u| u.settings.nil? }
  validates :api_key_id, absence: true, if: proc { |u| u.type.nil? }
  validates_presence_of :name

  serialize :cached_teams, Array

  check_settings

  include DeviseAsync

  ROLES = %w[collaborator editor admin]

  def role?(base_role, team = nil)
    role = self.role(team)
    return true if role.to_s == base_role.to_s
    return false if !ROLES.include?(base_role.to_s) || !ROLES.include?(role.to_s)
    ROLES.index(base_role.to_s) <= ROLES.index(role) unless role.nil?
  end

  def role(team = nil)
    context_team = team || Team.current || self.current_team
    return nil if context_team.nil? || context_team.new_record?
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

  def me
    User.current&.id == self.id ? self : nil
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
    avatar = image ? image.gsub(/^http:/, 'https:') : self.avatar
    self.source.set_avatar(avatar)
  end

  def avatar
    custom = self.reload.image&.file&.public_url&.to_s
    default = CheckConfig.get('checkdesk_base_url') + self.image.url
    custom || default
  end

  def as_json(_options = {})
    user = {
      id: Base64.encode64("User/#{self.id}"),
      dbid: self.id,
      teams: self.user_teams,
      source_id: self.source&.id
    }
    [:name, :email, :login, :token, :current_team, :team_ids, :permissions, :profile_image, :settings, :is_admin, :accepted_terms, :last_accepted_terms_at].each do |field|
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
    self.is_active? ? super :  I18n.t(:banned_user, app_name: CheckConfig.get('app_name'), support_email: CheckConfig.get('support_email'))
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
    # As we must invite users first then the email must exists
    # which means the handle is email address
    self.email
  end

  # Whether two users are members of any same team
  def is_a_colleague_of?(user)
    params = ['SELECT COUNT(*) AS number_of_common_teams FROM team_users tu1 INNER JOIN team_users tu2 ON tu1.team_id = tu2.team_id WHERE tu1.user_id = ? AND tu2.user_id = ? AND tu1.status = ? AND tu2.status = ?', self.id, user.id, 'member', 'member']
    results = ApplicationRecord.connection.execute(ApplicationRecord.send(:sanitize_sql_array, params))
    results[0]['number_of_common_teams'].to_i >= 1
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

  def is_confirmed?
    self.confirmed? && self.unconfirmed_email.nil?
  end

  def send_email_notifications=(enabled)
    set_user_notification_settings('send_email_notifications', enabled)
  end

  def send_successful_login_notifications=(enabled)
    set_user_notification_settings('send_successful_login_notifications', enabled)
  end

  def send_failed_login_notifications=(enabled)
    set_user_notification_settings('send_failed_login_notifications', enabled)
  end

  def profile_image
    self.source.nil? ? nil : self.source.image
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
    self.last_accepted_terms_at.to_i > User.terms_last_updated_at
  end

  def self.terms_last_updated_at
    # Cached value should be an integer timestamp i.e Time.now.to_i
    Rails.cache.read('terms_last_updated_at').to_i || 0
  end

  def self.delete_check_user(user)
    begin
      user.send(:freeze_account_ids_and_source_id)
      rand_id = Time.now.to_i
      s = user.source
      columns = {
        name: "Anonymous", login: "Anonymous", token: "#{user.token}-#{rand_id}",
        email: nil, source_id: nil, is_active: false
      }
      user.update_columns(columns)
      # update cached field that affected by change user name
      pm_ids = user.project_medias.where("channel->>'main'IN (?)", [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::BROWSER_EXTENSION].map(&:to_s)).map(&:id)
      pm_ids.each{ |pm_id| Rails.cache.write("check_cached_field:ProjectMedia:#{pm_id}:creator_name", 'Anonymous') }
      # delete source profile and accounts
      self.delete_user_profile(s) unless s.nil?
      # update team user status
      TeamUser.where(user_id: user.id).update_all(status: 'banned')
    rescue StandardError => e
      raise e.message
    end
    # notify team(s) owner & privacy
    DeleteUserMailer.send_notification(user, user.teams)
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

  def merge_with(user)
    return if self.id == user.id
    merged_tu = merge_shared_teams(user)
    # remove shared accounts on both sources
    s = self.source
    s2 = user.source
    unless s2.nil?
      as = AccountSource.where(source_id: s2.id, account_id: s.accounts)
      as.each{|i| i.skip_check_ability = true; i.destroy;}
    end

    # Remove duplicate ProjectMediaUser before merging
    data = ProjectMediaUser.select('project_media_id').where(user_id: [user.id, self.id])
    .group('project_media_id').having("count(project_media_id) = ?", 2)
    ProjectMediaUser.where(project_media_id: data.map(&:project_media_id), user_id: user.id).delete_all

    all_associations = User.reflect_on_all_associations(:has_many).select{|a| a.foreign_key == 'user_id'}
    all_associations.each do |assoc|
      assoc.class_name.constantize.where(assoc.foreign_key => user.id).update_all(assoc.foreign_key => self.id)
    end
    Annotation.where(annotator_id: user.id, annotator_type: 'User').update_all(annotator_id: self.id)
    merged_tu.map(&:team_id).uniq.each{ |team_id| Version.from_partition(team_id).where(whodunnit: user.id).update_all(whodunnit: self.id) }
    # update cached teams and encrypted_password for merged user
    columns = {}
    if !self.encrypted_password? && user.encrypted_password?
      columns = {encrypted_password: user.encrypted_password, email: user.email, token: user.token}
    end
    columns[:is_admin] = true if user.is_admin?
    columns[:cached_teams] = TeamUser.where(user_id: self.id, status: 'member').map(&:team_id)
    user.skip_check_ability = true
    user.destroy
    self.merge_source(s, s2)
    self.update_columns(columns)
  end

  def merge_source(s, s2)
    unless s2.nil?
      AccountSource.where(source_id: s2.id).update_all(source_id: s.id)
      s2.skip_check_ability = true
      s2_count = User.where(source_id: s2.id).count
      s2.destroy if s2_count == 0
    end
  end

  def merge_shared_teams(u)
    merged_tu = []
    # handle case that both users exists on same team by kepping a higher role
    teams = TeamUser.select("team_id").where(user_id: [self.id, u.id]).group("team_id").having("count(team_id) = ?", 2).map(&:team_id)
    teams.each do |t|
      tu = TeamUser.where(user_id: [self.id, u.id], team_id: t)
      low_role = tu.sort_by{|x| ROLES.find_index(x.role)}.first
      merged_tu.concat(tu.to_a - [low_role])
      low_role.skip_check_ability = true
      low_role.destroy
    end
    merged_tu
  end

  def self.get_duplicate_user(email, id=0)
    ret = { user: nil, type: nil }
    unless email.blank?
      u = User.where('lower(email) = ?', email.downcase).where.not(id: id).last
      if u.nil?
        # check email in social accounts
        a = Account.where('lower(email) = ?', email.downcase).where.not(user_id: id).last
        ret = { user: a.user, type: a.class_name } unless a.nil?
      else
        ret = { user: u, type: u.class_name }
      end
    end
    ret
  end

  def self.find_user_by_email(email)
    u = User.where(email: email).last
    if u.nil?
      a = Account.where(email: email).last if u.nil?
      u = a.user unless a.nil?
    end
    u
  end

  def self.reset_change_password(inputs)
    if inputs[:reset_password_token].blank?
      user = User.where(id: inputs[:id]).last
      if user.nil? || User.current.id != inputs[:id]
        raise ActiveRecord::RecordNotFound
      else
        if user.encrypted_password? && !user.valid_password?(inputs[:current_password])
          raise I18n.t(:"errors.messages.invalid_password")
        end
        user.reset_password(inputs[:password], inputs[:password_confirmation])
      end
    else
      user = User.reset_password_by_token(inputs)
    end
    user
  end

  def owns_media?
    ProjectMedia.where(user_id: self.id).count > 0
  end

  def intercom_user_jwt
    require 'jwt'
    payload = {
      user_id: self.id,
      email: self.email,
      name: self.name,
      check_workspace: self.current_team&.slug,
      exp: Time.now.to_i + 3600,
    }
    JWT.encode(payload, CheckConfig.get('intercom_api_secret'), 'HS256')
  end

  # private
  #
  # Please add private methods to app/models/concerns/user_private.rb
end
