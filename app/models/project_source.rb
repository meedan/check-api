class ProjectSource < ActiveRecord::Base
  belongs_to :project
  belongs_to :source
end
