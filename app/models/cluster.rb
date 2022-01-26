class Cluster < ApplicationRecord
  belongs_to :project_media # Item that is the cluster center
  has_many :project_medias, dependent: :nullify, after_add: [:update_elastic_search, :update_team_names_cache] # Items that belong to the cluster
  validates_presence_of :project_media_id
  validates_uniqueness_of :project_media_id
  validate :center_is_not_part_of_another_cluster

  def center
    self.project_media
  end

  def items
    self.project_medias
  end

  def size
    self.project_medias_count
  end

  def team_names(force = false)
    Rails.cache.fetch("cluster:team_names:#{self.id}", force: force) do
      self.project_medias.collect{ |pm| pm.team&.name }.reject{ |t| t.blank? }.uniq.sort
    end
  end

  private

  def center_is_not_part_of_another_cluster
    errors.add(:base, I18n.t(:center_is_not_part_of_another_cluster)) if self.center&.cluster_id && self.center&.cluster_id != self.id
  end

  def update_elastic_search(_item)
    es_body = [
      {
        update: {
          _index: ::CheckElasticSearchModel.get_index_alias,
          _id: Base64.encode64("ProjectMedia/#{self.project_media_id}"),
          retry_on_conflict: 3,
          data: { doc: { cluster_size: self.project_medias.count } }
        }
      }
    ]
    $repository.client.bulk(body: es_body)
  end

  def update_team_names_cache(_item)
    self.team_names(true)
  end
end
