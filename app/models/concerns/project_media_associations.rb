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
    belongs_to :cluster, counter_cache: true, optional: true
    belongs_to :source, optional: true
    has_annotations
  end
end
