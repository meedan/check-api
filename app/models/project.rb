class Project < ActiveRecord::Base
  attr_accessible
  
  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :team
  has_many :project_sources
  has_many :sources , through: :project_sources
  has_many :project_medias
  has_many :medias , through: :project_medias

  mount_uploader :lead_image, ImageUploader
  
  before_validation :set_description_and_team_and_user, on: :create

  validates_presence_of :title
  validates :lead_image, size: true

  has_annotations

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def lead_image_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    CONFIG['checkdesk_base_url'] + self.lead_image.url
  end

  def as_json(options = {})
    project = {
      dbid: self.id,
      title: self.title,
      id: Base64.encode64("Project/#{self.id}")
    }
    unless options[:without_team]
      project[:team] = {
        id: Base64.encode64("Team/#{self.id}"),
        dbid: self.team_id,
        projects: { edges: self.team.projects.collect{ |p| { node: p.as_json(without_team: true) } } }
      }
    end
    project
  end

  private

  def set_description_and_team_and_user
    self.description ||= ''
    if !self.current_user.nil? && !self.team_id
      self.team = self.current_user.current_team
    end
    self.user ||= self.current_user
  end
end
