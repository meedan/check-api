class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media

  def get_team
    p = self.project
    p.nil? ? [nil] : [p.team_id]
  end

  def media_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

end
