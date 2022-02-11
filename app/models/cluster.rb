class Cluster < ApplicationRecord
  belongs_to :project_media # Item that is the cluster center
  has_many :project_medias, dependent: :nullify, after_add: [:update_elastic_search, :update_cached_fields, :update_timestamps] # Items that belong to the cluster
  validates_presence_of :project_media_id
  validates_uniqueness_of :project_media_id
  validate :center_is_not_part_of_another_cluster

  ::Dynamic.class_eval do
    after_save do
      if self.annotation_type == 'report_design'
        cluster = self.annotated&.cluster
        es_body = [
          {
            update: {
              _index: ::CheckElasticSearchModel.get_index_alias,
              _id: Base64.encode64("ProjectMedia/#{cluster&.project_media_id}"),
              retry_on_conflict: 3,
              data: { doc: { cluster_report_published: 1 } }
            }
          }
        ]
        $repository.client.bulk(body: es_body) unless cluster.nil?
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

  def requests_count
    self.project_medias.select(:id).collect{ |pm| pm.requests_count }.sum
  end

  def get_team_names
    self.project_medias.group(:team_id).count.keys.collect{ |tid| Team.find_by_id(tid)&.name }
  end

  def get_names_of_teams_that_fact_checked_it
    Dynamic
      .where(annotation_type: 'report_design')
      .where('data LIKE ?', '%state: published%')
      .joins("INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia' AND annotations.annotated_id = pm.id INNER JOIN clusters c ON c.id = pm.cluster_id")
      .where('c.id' => self.id)
      .group(:team_id)
      .count.keys.collect{ |tid| Team.find_by_id(tid)&.name }
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
    update_es: false,
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
    self.fact_checked_by_team_names(true)
  end

  def update_timestamps(item)
    self.first_item_at = item.created_at if item.created_at.to_i < self.first_item_at.to_i || self.first_item_at.to_i == 0
    self.last_item_at = item.created_at if item.created_at.to_i > self.last_item_at.to_i
    self.save!
  end
end
