class ProjectSource < ActiveRecord::Base
  attr_accessible :project_id, :source_id

  belongs_to :project
  belongs_to :source
end
