class Media < ActiveRecord::Base
  self.inheritance_column = :type

  attr_accessible
  attr_accessor :project_id, :project_object

  has_paper_trail on: [:create, :update]
  belongs_to :account
  belongs_to :user
  has_many :project_medias
  has_many :projects, through: :project_medias
  has_annotations

  before_validation :set_type, :set_url_nil_if_empty, :set_user, on: :create
  after_create :set_project

  def self.types
    %w(Link Claim)
  end
  
  validates_inclusion_of :type, in: Media.types

  def current_team
    self.project.team if self.project
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def account_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

  def pm_dbid(context)
    pm = self.project_medias.find_by(:project_id => context.id) unless context.nil?
    pm.nil? ? 0 : pm.id
  end

  def project_media(context = nil)
    context = self.get_media_context(context)
    self.project_medias.find_by(:project_id => context.id) unless context.nil?
  end

  def get_team
    self.projects.map(&:team_id)
  end

  def get_team_objects
    self.projects.map(&:team)
  end

  def associate_to_project
    if !self.project_id.blank? && !ProjectMedia.where(project_id: self.project_id, media_id: self.id).exists?
      pm = ProjectMedia.new
      pm.project_id = self.project_id
      pm.media = self
      pm.user = User.current
      pm.save!
    end
  end

  def relay_id
    str = "Media/#{self.id}"
    str += "/#{self.project_id}" unless self.project_id.nil?
    Base64.encode64(str)
  end

  def get_media_context(context = nil)
    context.nil? ? self.project : context
  end

  def project
    return self.project_object unless self.project_object.nil?
    if self.project_id
      Rails.cache.fetch("project_#{self.project_id}", expires_in: 30.seconds) do
        Project.find(self.project_id)
      end
    end
  end

  def overriden_embed_attributes
    %W(title description username quote)
  end

  private

  def set_url_nil_if_empty
    self.url = nil if self.url.blank?
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_project
    self.associate_to_project
  end

  def set_type
    if self.type.blank?
      if self.url.blank?
        self.type = 'claim' unless self.quote.blank?
      else
        self.type = 'link'
      end
    end
  end
end
