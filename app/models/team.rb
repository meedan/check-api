class Team < ActiveRecord::Base
  attr_accessible
  
  has_paper_trail on: [:create, :update]
  has_many :projects
  has_many :accounts
  has_many :team_users
  has_many :users, through: :team_users
  has_many :contacts

  mount_uploader :logo, ImageUploader

  before_validation :normalize_subdomain, on: :create

  validates_presence_of :name
  validates_presence_of :subdomain
  validates_format_of :subdomain, :with => /\A[[:alnum:]-]+\z/, :message => 'accepts only letters, numbers and hyphens', on: :create
  validates :subdomain, length: { in: 4..63 }, on: :create
  validates :subdomain, uniqueness: true, on: :create
  validate :subdomain_is_available, on: :create
  validates :logo, size: true
  validate :slack_webhook_format
  validate :custom_media_statuses_format
  validate :custom_source_statuses_format

  after_create :add_user_to_team

  has_annotations

  include CheckdeskSettings

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
      subdomain: self.subdomain
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

  protected

  def custom_statuses_format(type)
    statuses = self.send("get_#{type}_verification_statuses")
    unless statuses.nil?
      if statuses[:label].blank? || !statuses[:statuses].is_a?(Array) || statuses[:statuses].size === 0
        errors.add(:base, 'Invalid format for custom verification statuses')
      else
        statuses[:statuses].each do |status|
          errors.add(:base, 'Invalid format for custom verification status') if status.keys.sort != [:description, :id, :label, :style]
        end
      end
    end
  end

  private

  def add_user_to_team
    user = self.current_user
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

  def self.subdomain_from_name(name)
    name.parameterize.underscore.dasherize.ljust(4, '-')
  end

  def subdomain_is_available
    unless self.origin.blank?
      begin
        r = Regexp.new CONFIG['checkdesk_client']
        m = origin.match(r)
        url = ''
        
        if m[1].blank?
          url = m[0].gsub(/(^https?:\/\/)/, '\1' + self.subdomain + '.')
        else
          url = m[0].gsub(m[1], self.subdomain)
        end

        uri = URI.parse(url)
        request = Net::HTTP::Head.new(uri)
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
        
        errors.add(:base, 'Subdomain is not available') unless response['X-Check-Web']
      rescue
        errors.add(:base, 'Subdomain is not available')
      end
    end
  end

  def slack_webhook_format
    webhook = self.get_slack_webhook
    if !webhook.blank? && /\Ahttps?:\/\/hooks\.slack\.com\/services\/[^\s]+\z/.match(webhook).nil?
      errors.add(:base, 'Slack webhook format is wrong')
    end
  end

  def normalize_subdomain
    self.subdomain = self.subdomain.downcase unless self.subdomain.blank?
  end

  def custom_media_statuses_format
    self.custom_statuses_format(:media)
  end

  def custom_source_statuses_format
    self.custom_statuses_format(:source)
  end
end
