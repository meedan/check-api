class Cluster < ApplicationRecord
  include CheckElasticSearch

  has_many :project_medias, dependent: :nullify, after_add: [:update_cached_fields, :update_elasticsearch_and_timestamps] # Items that belong to the cluster
  has_many :cluster_project_medias, dependent: :destroy
  has_many :project_medias, through: :cluster_project_medias

  belongs_to :feed

  validate :center_is_not_part_of_another_cluster

  after_destroy :update_elasticsearch

  def center
    self.items.first
  end

  def items
    self.project_medias
  end

  def size
    self.project_medias_count
  end

  def get_requests_count
    self.project_medias.select(:id).collect{ |pm| pm.requests_count }.sum
  end

  def get_team_names
    data = {}
    self.project_medias.group(:team_id).count.keys.collect{ |tid| Team.find_by_id(tid)&.name }
    tids = self.project_medias.group(:team_id).count.keys
    Team.where(id: tids).find_each { |t| data[t.id] = t.name }
    data
  end

  def get_names_of_teams_that_fact_checked_it
    data = {}
    j = "INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia' AND annotations.annotated_id = pm.id INNER JOIN cluster_project_medias cpm ON cpm.project_media_id = pm.id"
    tids = Dynamic.where(annotation_type: 'report_design').where('data LIKE ?', '%state: published%')
    .joins(j).where('cpm.cluster_id' => self.id).group(:team_id).count.keys
    Team.where(id: tids).find_each { |t| data[t.id] = t.name }
    # update ES count field
    pm = self.center
    unless pm.nil?
      options = {
        keys: ['cluster_published_reports_count'],
        data: { 'cluster_published_reports_count' => data.size },
        pm_id: pm.id
      }
      model = { klass: pm.class.name, id: pm.id }
      ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(options), 'update_doc')
    end
    data
  end

  def claim_descriptions
    pm_ids = self.project_media_ids
    # ClaimDescription.joins(:project_media).where('project_medias.cluster_id' => self.id)
    ClaimDescription.where(project_media_id: pm_ids)
  end

  cached_field :team_names,
    start_as: proc { |c| c.get_team_names },
    recalculate: :recalculate_team_names,
    update_on: [] # Handled by an "after_add" callback above

  cached_field :fact_checked_by_team_names,
    start_as: proc { |c| c.get_names_of_teams_that_fact_checked_it },
    update_es: :cached_field_fact_checked_by_team_names_es,
    es_field_name: :cluster_published_reports,
    recalculate: :recalculate_fact_checked_by_team_names,
    update_on: [
      # Also handled by an "after_add" callback above
      {
        model: Dynamic,
        if: proc { |d| d.annotation_type == 'report_design' },
        affected_ids: proc { |d| ClusterProjectMedia.where(project_media_id: d.annotated.related_items_ids).group(:cluster_id).count.keys.reject{ |cid| cid.nil? } },
        events: {
          save: :recalculate
        }
      }
    ]

  cached_field :requests_count,
    start_as: proc { |c| c.get_requests_count },
    update_es: true,
    es_field_name: :cluster_requests_count,
    recalculate: :recalculate_requests_count,
    update_on: [
        {
          model: TiplineRequest,
          if: proc { |tr| tr.associated_type == 'ProjectMedia' },
          affected_ids: proc { |tr| ClusterProjectMedia.where(project_media_id: tr.associated.related_items_ids).group(:cluster_id).count.keys.reject{ |cid| cid.nil? } },
          events: {
            create: :cached_field_cluster_requests_count_create,
            destroy: :cached_field_cluster_requests_count_destroy
          }
        }
      ]

  def recalculate_team_names
    self.get_team_names
  end

  def recalculate_fact_checked_by_team_names
    self.get_names_of_teams_that_fact_checked_it
  end

  def recalculate_requests_count
    self.get_requests_count
  end

  def cached_field_fact_checked_by_team_names_es(value)
    value.keys
  end

  private

  def center_is_not_part_of_another_cluster
    errors.add(:base, I18n.t(:center_is_not_part_of_another_cluster)) if self.center&.cluster_id && self.center&.cluster_id != self.id
  end

  def update_cached_fields(_item)
    self.team_names(true)
    self.fact_checked_by_team_names(true)
    self.requests_count(true)
  end

  def update_elasticsearch_and_timestamps(item)
    self.first_item_at = item.created_at if item.created_at.to_i < self.first_item_at.to_i || self.first_item_at.to_i == 0
    self.last_item_at = item.created_at if item.created_at.to_i > self.last_item_at.to_i
    self.skip_check_ability = true
    self.save!
    # update ES
    pm = self.project_media
    data = {
      'cluster_size' => self.project_medias.count,
      'cluster_first_item_at' => self.first_item_at.to_i,
      'cluster_last_item_at' => self.last_item_at.to_i,
      'cluster_published_reports' => self.fact_checked_by_team_names.keys,
      'cluster_published_reports_count' => self.fact_checked_by_team_names.size,
      'cluster_requests_count' => self.requests_count,
      'cluster_teams' => self.team_names.keys,
    }
    options = { keys: data.keys, data: data, pm_id: pm.id }
    model = { klass: pm.class.name, id: pm.id }
    ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(options), 'update_doc')
  end

  def update_elasticsearch
    pm = self.center
    unless pm.nil?
      keys = ['cluster_size', 'cluster_first_item_at', 'cluster_last_item_at', 'cluster_published_reports_count', 'cluster_requests_count']
      data = {}
      keys.each { |k| data[k] = 0 }
      options = { keys: keys, data: data, pm_id: pm.id }
      model = { klass: pm.class.name, id: pm.id }
      ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(options), 'update_doc')
    end
  end
end
