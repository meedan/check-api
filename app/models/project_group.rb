class ProjectGroup < ApplicationRecord
  attr_accessor :is_being_copied

  validates_presence_of :title, :team_id
  validates :title, uniqueness: { scope: :team_id }, unless: proc { |pg| pg.is_being_copied }

  belongs_to :team, optional: true
  has_many :projects, dependent: :nullify

  def medias_count
    self.projects.map(&:medias_count).sum
  end

  def project_medias
    ProjectMedia.joins(:project).where('projects.project_group_id' => self.id)
  end
end
