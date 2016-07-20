class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media

  def media_id_callback(value, _mapping_ids = nil)
    media_id = _mapping_ids[value]
  end

  def project_id_callback(value, _mapping_ids = nil)
    project_id = _mapping_ids[value]
  end

end
