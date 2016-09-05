class ProjectSource < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :source

  def get_team
    p = self.project
    [p.team_id]
  end
end
