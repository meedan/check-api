class ClusterProjectMedia < ApplicationRecord
  belongs_to :cluster
  belongs_to :project_media

  validates_presence_of :cluster_id
  validates_presence_of :project_media_id
end
