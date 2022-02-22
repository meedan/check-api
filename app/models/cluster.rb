class Cluster < ApplicationRecord
  include CheckElasticSearch

  belongs_to :project_media # Item that is the cluster center
  has_many :project_medias, dependent: :nullify, after_add: [:update_cached_fields, :update_elasticsearch_and_timestamps] # Items that belong to the cluster
  validates_presence_of :project_media_id
  validates_uniqueness_of :project_media_id
  validate :center_is_not_part_of_another_cluster

  ::Dynamic.class_eval do
    after_save do
      if self.annotation_type == 'report_design'
        cluster = self.annotated&.cluster
        unless cluster.nil?
          pm = cluster.project_media
          options = { keys: ['cluster_report_published'], data: { 'cluster_report_published' => 1 }, obj: pm }
          ElasticSearchWorker.perform_in(1.second, YAML::dump(pm), YAML::dump(options), 'update_doc')
        end
      end
    end
  end

  def center
    self.project_media
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
    self.project_medias.group(:team_id).count.keys.collect{ |tid| Team.find_by_id(tid)&.name }
  end

  def get_names_of_teams_that_fact_checked_it
    j = "INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia' AND annotations.annotated_id = pm.id INNER JOIN clusters c ON c.id = pm.cluster_id"
    Dynamic.where(annotation_type: 'report_design').where('data LIKE ?', '%state: published%').joins(j).where('c.id' => self.id).group(:team_id).count.keys.collect{ |tid| Team.find_by_id(tid)&.name }
  end

  def claim_descriptions
    ClaimDescription.joins(:project_media).where('project_medias.cluster_id' => self.id)
  end

  cached_field :team_names,
    start_as: proc { |c| c.get_team_names },
    update_es: false,
    recalculate: proc { |c| c.get_team_names },
    update_on: [] # Handled by an "after_add" callback above

  cached_field :fact_checked_by_team_names,
    start_as: proc { |c| c.get_names_of_teams_that_fact_checked_it },
    update_es: proc { |_pm, value| value.size },
    es_field_name: :cluster_published_reports_count,
    recalculate: proc { |c| c.get_names_of_teams_that_fact_checked_it },
    update_on: [
      # Also handled by an "after_add" callback above
      {
        model: Dynamic,
        if: proc { |d| d.annotation_type == 'report_design' },
        affected_ids: proc { |d| ProjectMedia.where(id: d.annotated.related_items_ids).group(:cluster_id).count.keys.reject{ |cid| cid.nil? } },
        events: {
          save: :recalculate
        }
      }
    ]

  cached_field :requests_count,
    start_as: proc { |c| c.get_requests_count },
    update_es: true,
    es_field_name: :cluster_requests_count,
    recalculate: proc { |c| c.get_requests_count },
    update_on: [
        {
          model: Dynamic,
          if: proc { |d| d.annotation_type == 'smooch' && d.annotated_type == 'ProjectMedia' },
          affected_ids: proc { |d| ProjectMedia.where(id: d.annotated.related_items_ids).group(:cluster_id).count.keys.reject{ |cid| cid.nil? } },
          events: {
            create: :recalculate,
            destroy: :recalculate
          }
        }
      ]

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
    keys = ['cluster_size', 'cluster_first_item_at', 'cluster_last_item_at']
    keys = ['cluster_size', 'cluster_first_item_at', 'cluster_last_item_at', 'cluster_published_reports_count', 'cluster_requests_count']
    pm = self.project_media
    data = {
      'cluster_size' => self.project_medias.count,
      'cluster_first_item_at' => self.first_item_at.to_i,
      'cluster_last_item_at' => self.last_item_at.to_i,
      'cluster_published_reports_count' => self.fact_checked_by_team_names.size,
      'cluster_requests_count' => self.requests_count,
    }
    options = { keys: keys, data: data, obj: pm }
    ElasticSearchWorker.perform_in(1.second, YAML::dump(pm), YAML::dump(options), 'update_doc')
  end
end
