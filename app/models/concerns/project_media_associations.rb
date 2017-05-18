require 'active_support/concern'

module ProjectMediaAssociations
  extend ActiveSupport::Concern

  included do
    include AnnotationBase::Association

    belongs_to :project
    belongs_to :media
    belongs_to :user
    has_annotations
  end
end
