module Montage::Collection
  include Montage::Base

  def name
    self.title
  end

  def project_id
    self.team_id
  end

  def project_as_montage_collection_json
    {
      id: self.id,
      created: self.created,
      modified: self.modified,
      name: self.name,
      project_id: self.project_id
    }
  end
end
