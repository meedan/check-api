class Source < ActiveRecord::Base
  self.inheritance_column = :type

  attr_accessor :disable_es_callbacks, :name, :slogan, :avatar

  include HasImage
  include CheckElasticSearch
  include ValidationsHelper

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

  after_create :create_source_identity, :create_team_source


  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def file_mandatory?
    false
  end

  def update_from_pender_data(data)
    self.update_name_from_data(data)
    return if data.nil?
    self.avatar = data['author_picture'] if !data['author_picture'].blank?
    self.slogan = data['description'].to_s if self.slogan.blank?
  end

  def update_name_from_data(data)
    gname = self.name ||= "Untitled-#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
    if data.nil?
      self.name = gname if self.name.blank?
    else
      self.name = data['author_name'].blank? ? gname : data['author_name'] if self.name.blank? or self.name.start_with?('Untitled-')
    end
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
    si = self.annotations.where(annotation_type: 'source_identity').last
    si = si.load unless si.nil?
    if si.nil?
      si = SourceIdentity.new
      si.annotated = self
      si.skip_check_ability = true
    end
    si.name = self.name
    si.bio = self.slogan
    si.file = self.avatar
    si.save!
  end

  def get_team_source
    self.team_sources.where(team_id: Team.current.id).last unless Team.current.nil?
  end

  def get_project_sources
    conditions = {}
    conditions[:project_id] = Team.current.projects unless Team.current.nil?
    self.project_sources.where(conditions)
  end

  private

  def set_user
    self.user = User.current unless User.current.nil?
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
end
