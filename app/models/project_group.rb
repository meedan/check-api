class ProjectGroup < ActiveRecord::Base
  validates_presence_of :title, :team_id

  belongs_to :team
  has_many :projects

  def medias_count
    self.projects.map(&:medias_count).sum
  end
end
