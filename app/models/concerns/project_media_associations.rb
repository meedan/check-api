require 'active_support/concern'

module ProjectMediaAssociations
  extend ActiveSupport::Concern

  included do
    include AnnotationBase::Association

    belongs_to :project
    belongs_to :media
    belongs_to :user
    has_many :target_relationships, class_name: 'Relationship', foreign_key: 'target_id', dependent: :destroy
    has_many :source_relationships, class_name: 'Relationship', foreign_key: 'source_id', dependent: :destroy
    has_many :sources, through: :target_relationships, source: :source 
    has_many :targets, through: :source_relationships, source: :target
    has_annotations
  end
end
