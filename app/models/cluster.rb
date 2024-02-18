class Cluster < ApplicationRecord
  include CheckElasticSearch

  has_many :cluster_project_medias, dependent: :destroy
  has_many :project_medias, through: :cluster_project_medias

  belongs_to :feed

  def center
    self.items.first
  end

  def items
    self.project_medias
  end

  def size
    self.project_medias_count
  end
end
