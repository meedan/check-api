class Source < ActiveRecord::Base
  self.inheritance_column = :type

  attr_accessor :disable_es_callbacks, :name, :slogan, :avatar

  include HasImage
  include CheckElasticSearch
  include CheckNotifications::Pusher
  include ValidationsHelper
  include CustomLock

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  has_many :team_sources
  has_many :project_sources
  has_many :account_sources, dependent: :destroy
  has_many :teams, through: :team_sources
  has_many :projects, through: :project_sources
  has_many :accounts, through: :account_sources
  belongs_to :user

  has_annotations

  before_validation :set_user, on: :create

  validate :source_is_unique, on: :create

  after_create :create_metadata, :create_source_identity, :create_team_source

  notifies_pusher on: :update, event: 'source_updated', data: proc { |s| s.to_json }, targets: proc { |s| [s] }

  custom_optimistic_locking include_attributes: [:name, :image, :description]

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
    file = source_identity['file']
    return CONFIG['checkdesk_base_url'] + file.url if !file.nil? && file.url != '/images/source.png'
    file || (self.accounts.empty? ? CONFIG['checkdesk_base_url'] + '/images/source.png' : self.accounts.first.data['picture'].to_s)
  end

  def get_name
    source_identity['name']
  end

  def description
    slogan = source_identity['bio']
    return slogan if slogan != source_identity['name'] && !slogan.nil?
    self.accounts.empty? ? '' : self.accounts.first.data['description'].to_s
  end

  def collaborators
    self.annotators
  end

  def get_annotations(type = nil)
    ts = get_team_source
    conditions = {}
    conditions[:annotation_type] = type unless type.nil?
    conditions[:annotated_type] = 'TeamSource'
    conditions[:annotated_id] = ts.id unless ts.nil?
    Annotation.where(conditions)
  end

  def file_mandatory?
    false
  end

  def get_versions_log
    PaperTrail::Version.where(associated_type: 'TeamSource', associated_id: get_team_source).order('created_at ASC')
  end

  def get_versions_log_count
    ts = get_team_source
    ts.nil? ? 0 : ts.cached_annotations_count
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
    si = Annotation.where(annotation_type: 'source_identity', annotated_type: 'Source').all.select {|a| a.name.downcase == name.downcase}
    si.first.annotated unless si.blank?
  end

  def self.create_source(name)
    s = self.get_duplicate_source(name)
    if s.blank?
      s = Source.new
      s.name = name
      s.save!
    else
      # Add team source
      TeamSource.find_or_create_by(team_id: Team.current.id, source_id: s.id) unless Team.current.nil?
    end
    s
  end

  def create_source_identity
    si = SourceIdentity.new
    si.name = self.name
    si.bio = self.slogan
    si.file = self.avatar
    si.annotated = self
    si.skip_check_ability = true
    si.save!
  end

  def get_team_source
    self.team_sources.where(team_id: Team.current.id).last unless Team.current.nil?
  end

  def identity=(info)
    info = info.blank? ? {} : JSON.parse(info)
    unless info.blank?
      type = (self.type == 'Profile') ? 'Source' : 'TeamSource'
      si = get_source_identity_annotation(type)
      ts = get_team_source
      return if ts.nil? && type == 'TeamSource'
      if si.nil?
        si = SourceIdentity.new
        si.annotated = ts
        si.annotator = User.current unless User.current.nil?
      end
      info.each{ |k, v| si.send("#{k}=", v) if si.respond_to?(k) and !v.blank? }
      si.skip_check_ability = true
      si.save!
    end
  end

  def source_identity
    data = {}
    attributes = %W(name bio file)
    si = get_source_identity_annotation
    attributes.each{|k| ks = k.to_s; data[ks] = si.send(ks) } unless si.nil?
    si = get_source_identity_annotation('TeamSource')
    attributes.each{|k| ks = k.to_s; data[ks] = si.send(ks) unless si.send(ks).nil? } unless si.nil?
    data
  end

  private

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def get_project_sources
    conditions = {}
    conditions[:project_id] = Team.current.projects unless Team.current.nil?
    self.project_sources.where(conditions)
  end

  def get_source_identity_annotation(type = 'Source')
    if type == 'Source'
      si = self.annotations.where(annotation_type: 'source_identity').last
    else
      ts = get_team_source
      si = ts.annotations.where(annotation_type: 'source_identity').last unless ts.nil?
    end
    si = si.load unless si.nil?
  end

  def source_is_unique
    duplicate = self.name.nil? ? nil : Source.get_duplicate_source(self.name)
    errors.add(:base, I18n.t(:duplicate_source)) unless duplicate.blank?
  end

  def create_team_source
    unless Team.current.nil? or self.type == 'Profile'
      ts = TeamSource.new
      ts.team_id = Team.current.id
      ts.source_id = self.id
      ts.save!
    end
  end

  def create_metadata
    unless DynamicAnnotation::AnnotationType.where(annotation_type: 'metadata').last.nil?
      user = User.current
      User.current = nil
      m = Dynamic.new
      m.skip_check_ability = true
      m.skip_notifications = true
      m.disable_es_callbacks = Rails.env.to_s == 'test'
      m.annotation_type = 'metadata'
      m.annotated = self
      m.annotator = user
      m.set_fields = { metadata_value: {}.to_json }.to_json
      m.save!
      User.current = user
    end
  end
end
