class ProjectSource < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :source
  has_annotations

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end
end
