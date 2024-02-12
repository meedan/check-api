class ClusterProjectMedia < ApplicationRecord
  belongs_to :cluster, optional: true
  belongs_to :project_media, optional: true

  validates_presence_of :cluster_id
  validates_presence_of :project_media_id

end
