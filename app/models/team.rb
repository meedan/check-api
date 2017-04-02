class Team < ActiveRecord::Base

  include ValidationsHelper
  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }

  has_many :projects, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :team_users, dependent: :destroy
  has_many :users, through: :team_users
  has_many :contacts, dependent: :destroy

  mount_uploader :logo, ImageUploader

  before_validation :normalize_slug, on: :create

  validates_presence_of :name
  validates_presence_of :slug
  validates_format_of :slug, with: /\A[[:alnum:]-]+\z/, message: I18n.t(:slug_format_validation_message, default: 'accepts only letters, numbers and hyphens'), on: :create
  validates :slug, length: { in: 4..63 }, on: :create
  validates :slug, uniqueness: true, on: :create
  validate :slug_is_not_reserved
  validates :logo, size: true
  validate :slack_webhook_format
  validate :slack_channel_format
  validate :custom_media_statuses_format, unless: proc { |p| p.settings.nil? || p.get_media_verification_statuses.nil? }
  validate :custom_source_statuses_format, unless: proc { |p| p.settings.nil? || p.get_source_verification_statuses.nil? }
  validate :checklist_format

  after_create :add_user_to_team

  has_annotations

  RESERVED_SLUGS = ['check']

  include CheckSettings

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    CONFIG['checkdesk_base_url'] + self.logo.url
  end

  def members_count
    self.users.count
  end

  def as_json(_options = {})
    {
      dbid: self.id,
      id: Base64.encode64("Team/#{self.id}"),
      avatar: self.avatar,
      name: self.name,
      projects: self.recent_projects,
      slug: self.slug
    }
  end

  def owners
    self.users.where('team_users.role' => 'owner')
  end

  def recent_projects
    self.projects.order('id DESC')
  end

  def contact=(info)
    contact = self.contacts.first || Contact.new
    info = JSON.parse(info)
    contact.web = info['web']
    contact.phone = info['phone']
    contact.location = info['location']
    contact.team = self
    contact.save!
  end

  def verification_statuses(type)
    statuses = self.send("get_#{type}_verification_statuses") || Status.core_verification_statuses(type)
    statuses.to_json
  end

  def recipients(requestor)
    owners = self.owners
    recipients = []
    if !owners.empty? && !owners.include?(requestor)
      recipients = owners.map(&:email).reject{ |m| m.blank? }
    end
    recipients
  end

  def media_verification_statuses=(statuses)
    self.send(:set_media_verification_statuses, statuses)
  end

  def source_verification_statuses=(statuses)
    self.send(:set_source_verification_statuses, statuses)
  end

  def slack_notifications_enabled=(enabled)
    self.send(:set_slack_notifications_enabled, enabled)
  end

  def slack_webhook=(webhook)
    self.send(:set_slack_webhook, webhook)
  end

  def slack_channel=(channel)
    self.send(:set_slack_channel, channel)
  end

  def checklist=(checklist)
    self.send(:set_checklist, checklist)
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'team', 'slug' => self.slug } })
  end

  def suggested_tags=(tags)
    self.send(:set_suggested_tags, tags)
  end

  protected

  def custom_statuses_format(type)
    statuses = self.send("get_#{type}_verification_statuses")
    if !statuses.is_a?(Hash) || statuses[:label].blank? || !statuses[:statuses].is_a?(Array) || statuses[:statuses].size === 0
      errors.add(:base, I18n.t(:invalid_format_for_custom_verification_status, default: 'Custom verification statuses is invalid, it should have the format as exemplified below the field'))
    else
      statuses[:statuses].each do |status|
        errors.add(:base, 'Custom verification statuses is invalid, it should have the format as exemplified below the field') if status.keys.map(&:to_sym).sort != [:description, :id, :label, :style]
      end
    end
  end

  private

  def add_user_to_team
    user = User.current
    unless user.nil?
      tu = TeamUser.new
      tu.user = user
      tu.team = self
      tu.role = 'owner'
      tu.save!

      user.current_team_id = self.id
      user.save!
    end
  end

  def self.slug_from_name(name)
    name.parameterize.underscore.dasherize.ljust(4, '-')
  end

  def self.current
    Thread.current[:team]
  end

  def self.current=(team)
    Thread.current[:team] = team
  end

  def self.slug_from_url(url)
    URI(url).path.split('/')[1]
  end

  def normalize_slug
    self.slug = self.slug.downcase unless self.slug.blank?
  end

  def custom_media_statuses_format
    self.custom_statuses_format(:media)
  end

  def custom_source_statuses_format
    self.custom_statuses_format(:source)
  end

  def slug_is_not_reserved
    errors.add(:slug, I18n.t(:slug_is_reserved, default: 'is reserved')) if RESERVED_SLUGS.include?(self.slug)
  end

end
