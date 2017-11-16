class Source < ActiveRecord::Base
  attr_accessor :disable_es_callbacks

  include HasImage
  include CheckElasticSearch
  include CheckNotifications::Pusher
  include ValidationsHelper

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  has_many :project_sources
  has_many :account_sources, dependent: :destroy
  has_many :projects, through: :project_sources
  has_many :accounts, through: :account_sources
  belongs_to :user
  belongs_to :team

  has_annotations

  before_validation :set_user, :set_team, on: :create

  validates_presence_of :name
  validates :name, uniqueness: { case_sensitive: false }
  validate :team_is_not_archived

  after_create :create_source_identity

  after_update :update_elasticsearch_source

  notifies_pusher on: :update, event: 'source_updated', data: proc { |s| s.to_json }, targets: proc { |s| [s] }

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def medias
    #TODO: fix me - list valid project media ids
    m_ids = Media.where(account_id: self.account_ids).map(&:id)
    m_ids.concat ClaimSource.where(source_id: self.id).map(&:media_id)
    conditions = { media_id: m_ids }
    conditions['projects.team_id'] = Team.current.id unless Team.current.nil?
    ProjectMedia.joins(:project).where(conditions)
  end

  def get_team
    teams = []
    projects = self.projects.map(&:id)
    teams = Project.where(:id => projects).map(&:team_id).uniq unless projects.empty?
    return teams
  end

  def image
    return CONFIG['checkdesk_base_url'] + self.file.url if !self.file.nil? && self.file.url != '/images/source.png'
    self.avatar || (self.accounts.empty? ? CONFIG['checkdesk_base_url'] + '/images/source.png' : self.accounts.first.data['picture'].to_s)
  end

  def description
    return self.slogan if self.slogan != self.name && !self.slogan.nil?
    self.accounts.empty? ? '' : self.accounts.first.data['description'].to_s
  end

  def collaborators
    self.annotators
  end

  def get_annotations(type = nil)
    conditions = {}
    conditions[:annotation_type] = type unless type.nil?
    conditions[:annotated_type] = 'ProjectSource'
    conditions[:annotated_id] = get_project_sources.map(&:id)
    self.annotations(type) + Annotation.where(conditions)
  end

  def file_mandatory?
    false
  end

  def update_elasticsearch_source
    return if self.disable_es_callbacks
    ps_ids = self.project_sources.map(&:id).to_a
    unless ps_ids.blank?
      parents = ps_ids.map{|id| Base64.encode64("ProjectSource/#{id}") }
      parents.each do |parent|
        self.update_media_search(%w(title description), {'title' => self.name, 'description' => self.description}, parent)
      end
    end
  end

  def get_versions_log
    PaperTrail::Version.where(associated_type: 'ProjectSource', associated_id: get_project_sources).order('created_at ASC')
  end

  def get_versions_log_count
    get_project_sources.sum(:cached_annotations_count)
  end

  def update_from_pender_data(data)
    self.update_name_from_data(data)
    return if data.nil?
    self.avatar = data['author_picture'] if !data['author_picture'].blank?
    self.slogan = data['description'].to_s if self.slogan.blank?
  end

  def update_name_from_data(data)
    if data.nil?
      self.name = 'Untitled' if self.name.blank?
    else
      self.name = data['author_name'].blank? ? 'Untitled' : data['author_name'] if self.name.blank? or self.name === 'Untitled'
    end
  end

  def refresh_accounts=(refresh)
    return if refresh.blank?
    self.accounts.each do |a|
      a.refresh_pender_data
      a.save!
    end
    self.update_from_pender_data(self.accounts.first.data)
    self.updated_at = Time.now
    self.save!
  end

  def self.get_duplicate_source(name)
    si = Annotation.where(annotation_type: 'sourceidentity', annotated_type: 'Source').all.select {|a| a.name.downcase == name.downcase}
    si.first.annotated unless si.blank?
  end

  def self.create_source(name)
    s = self.get_duplicate_source(name)
    if s.blank?
      s = Source.new
      s.name = name
      s.save!
    end
    # Add team source
    TeamSource.find_or_create_by(team_id: Team.current.id, source_id: s.id) unless Team.current.nil?
    s
  end

  def find_duplicate_sources
    # This method for migration
    d = Source.where.not(id: self.id).where('lower(name) =  ?', self.name.downcase).map(&:id)
    d.concat AccountSource.where.not(source_id: self.id).where(account: self.accounts).map(&:source_id)
    d.uniq
  end

  def create_source_identity
    si = SourceIdentity.new
    si.name = self.name
    si.bio = self.slogan
    # si.file = self.avatar
    si.annotated = self
    si.skip_check_ability = true
    si.save!
  end

  private

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_team
    self.team = Team.current unless Team.current.nil?
  end

  def get_project_sources
    conditions = {}
    conditions[:project_id] = Team.current.projects unless Team.current.nil?
    self.project_sources.where(conditions)
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived_for_source, default: "Can't create source under trashed team"))
  end
end
