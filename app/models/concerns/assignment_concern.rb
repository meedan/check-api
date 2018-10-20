require 'active_support/concern'

# This concern expects that the model that includes it has a `assignments` relationship

module AssignmentConcern
  extend ActiveSupport::Concern

  def version_metadata(changes)
    return RequestStore[:task_comment].to_json if !RequestStore[:task_comment].blank? && RequestStore[:task_comment].annotated == self
    nil
  end

  # We can't simply use assignments= from Active Record here because it doesn't call the callbacks
  def assigned_to_ids=(csids)
    new_ids = csids.to_s.split(',').map(&:to_i)
    current_ids = self.reload.assignments.map(&:user_id)
    to_create = new_ids - current_ids
    to_delete = current_ids - new_ids
    to_delete.each do |id|
      Assignment.where(annotation_id: self.id, user_id: id).last.destroy!
    end
    to_create.each do |id|
      Assignment.create!(annotation_id: self.id, user_id: id)
    end
  end

  def users
    User.joins(:assignments).where('assignments.annotation_id' => self.id)
  end

  def assign_user(id)
    Assignment.create!(user_id: id, annotation_id: self.id)
  end

  module ClassMethods
    def assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      self.joins(:assignments).where('assignments.user_id' => uid)
    end

    def project_media_assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      ProjectMedia
      .joins("INNER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id INNER JOIN assignments a2 ON a2.annotation_id = a.id")
      .where('a2.user_id' => uid)
      .distinct
    end
  end

  included do
    has_many :assignments, foreign_key: :annotation_id, dependent: :destroy
  end
end
