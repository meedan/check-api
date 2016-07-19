class ProjectMedia < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :media

end
