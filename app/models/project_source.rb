class ProjectSource < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :source
  has_annotations

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def tags
    self.annotations('tag')
  end

  def comments
    self.annotations('comment')
  end

  def collaborators
    self.annotators
  end

end
