require 'active_support/concern'

module ProjectMediaAssociations
  extend ActiveSupport::Concern

  included do
    include AnnotationBase::Association

    belongs_to :media, optional: true
    belongs_to :user, optional: true
    belongs_to :team, optional: true
    belongs_to :project, optional: true
    has_many :target_relationships, class_name: 'Relationship', foreign_key: 'target_id'
    has_many :source_relationships, class_name: 'Relationship', foreign_key: 'source_id'
    has_many :sources, through: :target_relationships, source: :source
    has_many :targets, through: :source_relationships, source: :target
    has_many :project_media_users, dependent: :destroy
    has_many :project_media_requests, dependent: :destroy
    has_many :cluster_project_medias, dependent: :destroy
    has_many :clusters, through: :cluster_project_medias
    has_one :claim_description, dependent: :nullify
    belongs_to :source, optional: true
    has_many :tipline_requests, as: :associated
    has_many :explainer_items, dependent: :destroy
    has_many :explainers, through: :explainer_items
    has_annotations
  end
end
