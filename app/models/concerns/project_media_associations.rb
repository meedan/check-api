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

  def related_reports
    ids = []
    self.source_relationships.each do |relationship|
      ids << relationship.target_id
      if relationship.has_flag?('transitive')
        ids << relationship.target.targets.map(&:id)
      end
    end
    self.target_relationships.each do |relationship|
      ids << relationship.source_id if relationship.has_flag?('commutative')
    end
    ids = ids.flatten.uniq.sort - [self.id]
    ProjectMedia.where(id: ids)
  end
end
