require 'active_support/concern'

module ProjectMediaAssociations
  extend ActiveSupport::Concern

  included do
    belongs_to :project
    belongs_to :media
    belongs_to :user
    has_annotations
  end
end
