class ClusterProjectMedia < ApplicationRecord
  include CheckElasticSearch

  belongs_to :cluster, optional: true
  belongs_to :project_media, optional: true

  validates_presence_of :cluster_id
  validates_presence_of :project_media_id

  after_create :update_cached_fields, :update_elasticsearch_and_timestamps, :update_project_medias_count
  after_destroy :update_project_medias_count

  private

  def update_cached_fields
    cluster = self.cluster
    cluster.team_names(true)
    cluster.fact_checked_by_team_names(true)
    cluster.requests_count(true)
  end

  def update_elasticsearch_and_timestamps
    item = self.project_media
    cluster = self.cluster
    cluster.first_item_at = item.created_at if item.created_at.to_i < cluster.first_item_at.to_i || cluster.first_item_at.to_i == 0
    cluster.last_item_at = item.created_at if item.created_at.to_i > cluster.last_item_at.to_i
    cluster.skip_check_ability = true
    cluster.save!
    # update ES
    pm = cluster.center
    data = {
      'cluster_size' => cluster.project_medias.count,
      'cluster_first_item_at' => cluster.first_item_at.to_i,
      'cluster_last_item_at' => cluster.last_item_at.to_i,
      'cluster_published_reports' => cluster.fact_checked_by_team_names.keys,
      'cluster_published_reports_count' => cluster.fact_checked_by_team_names.size,
      'cluster_requests_count' => cluster.requests_count,
      'cluster_teams' => cluster.team_names.keys,
    }
    options = { keys: data.keys, data: data, pm_id: pm.id }
    model = { klass: pm.class.name, id: pm.id }
    ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(options), 'update_doc')
  end

  def update_project_medias_count
    self.cluster.update_columns(project_medias_count: self.cluster.project_medias.count)
  end
end
