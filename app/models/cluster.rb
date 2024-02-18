class Cluster < ApplicationRecord
  include CheckElasticSearch

  has_many :cluster_project_medias, dependent: :destroy
  has_many :project_medias, through: :cluster_project_medias

  belongs_to :feed
  belongs_to :project_media # Center

  def center
    self.project_media || self.items.first
  end

  def items
    self.project_medias
  end

  def size
    self.project_medias.count
  end
end
