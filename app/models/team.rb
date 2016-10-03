class Team < ActiveRecord::Base
  attr_accessible
  
  has_paper_trail on: [:create, :update]
  has_many :projects
  has_many :accounts
  has_many :team_users
  has_many :users, through: :team_users
  has_many :contacts

  mount_uploader :logo, ImageUploader

  validates_presence_of :name
  validates_presence_of :subdomain
  validates_format_of :subdomain, :with => /\A[[:alnum:]-]+\z/, :message => 'accepts only letters, numbers and hyphens'
  validates :subdomain, length: { in: 4..63 }
  validates :subdomain, uniqueness: true
  validate :subdomain_is_available
  validates :logo, size: true

  after_create :add_user_to_team

  has_annotations

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
end
