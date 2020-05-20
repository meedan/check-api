require 'active_support/concern'

# This concern expects that the model that includes it has a `assignments` relationship

module AssignmentConcern
  extend ActiveSupport::Concern

  def version_metadata(_changes)
    return RequestStore[:task_comment].to_json if !RequestStore[:task_comment].blank? && RequestStore[:task_comment].annotated == self
    nil
  end

  # We can't simply use assignments= from Active Record here because it doesn't call the callbacks
  def save_assignments
    csids = self.assigned_to_ids
    klass = self.is_annotation? ? 'Annotation' : self.class.name
    unless csids.nil?
      new_ids = csids.to_s.split(',').map(&:to_i)
      current_ids = self.reload.assignments.map(&:user_id)
      to_create = new_ids - current_ids
      to_delete = current_ids - new_ids
      to_delete.each do |id|
        Assignment.where(assigned_type: klass, assigned_id: self.id, user_id: id).last.destroy!
      end
      to_create.each do |id|
        Assignment.create!(assigned_type: klass, assigned_id: self.id, user_id: id)
      end
      # Save the assignment details to send them as Slack notifications
      self.instance_variable_set("@assignment", { to_create: to_create, to_delete: to_delete }) unless to_delete.blank? and to_create.blank?
    end
  end

  def slack_params_assignment
    {
      assigned: self.assigned_users()&.collect{ |u| u.name }&.to_sentence,
      assignment_event: self.instance_variable_get("@assignment").blank? ? nil : self.instance_variable_get("@assignment")[:to_create].blank? ? 'unassign' : 'assign',
      unassigned: self.instance_variable_get("@assignment").blank? ? nil : self.instance_variable_get("@assignment")[:to_delete].collect{ |uid| User.find(uid).name }&.to_sentence
    }
  end

  def assigned_users
    klass = self.is_annotation? ? 'Annotation' : self.class.name
    User.joins(:assignments).where('assignments.assigned_id' => self.id, 'assignments.assigned_type' => klass)
  end

  def assign_user(id)
    klass = self.is_annotation? ? 'Annotation' : self.class.name
    Assignment.create!(user_id: id, assigned_id: self.id, assigned_type: klass)
  end

  # Re-implement this method on the assigned class
  # The idea here is to return a list of objects that should be assigned to the same user
  # def propagate_assignment_to(user = nil)
  #   []
  # end

  module ClassMethods
    def assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      self.joins(:assignments).where('assignments.user_id' => uid)
    end

    def project_media_assigned_to_user(user, select = nil)
      uid = user.is_a?(User) ? user.id : user
      pmids = []
      pids = []
      assignments = Assignment.where(user_id: uid).includes(:assigned).to_a
      assignments.each do |a|
        if a.assigned_type == 'Annotation'
          pmids << a.assigned&.annotated_id
        elsif a.assigned_type == 'Project'
          pids << a.assigned_id
        end
      end
      pms = ProjectMedia.where('project_medias.id IN (?) OR project_medias.project_id IN (?)', pmids.uniq.reject{ |pmid| pmid.blank? }, pids)
      pms = pms.select(select) unless select.nil?
      pms
    end
  end

  included do
    attr_accessor :assigned_to_ids

    after_save :save_assignments

    has_many :assignments, as: :assigned, foreign_key: :assigned_id, dependent: :destroy
  end
end
