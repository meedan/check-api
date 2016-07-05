class ProjectSource < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :source
end
