require 'active_support/concern'

module ProjectMediaAssociations
  extend ActiveSupport::Concern

  included do
    include AnnotationBase::Association

    belongs_to :media
    belongs_to :user
    belongs_to :team
    has_many :target_relationships, class_name: 'Relationship', foreign_key: 'target_id'
    has_many :source_relationships, class_name: 'Relationship', foreign_key: 'source_id'
    has_many :sources, through: :target_relationships, source: :source
    has_many :targets, through: :source_relationships, source: :target
    has_many :project_media_projects, dependent: :destroy
    has_many :projects, through: :project_media_projects
    has_many :project_media_users, dependent: :destroy
    belongs_to :source
    has_annotations
  end
end
