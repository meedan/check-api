require 'active_support/concern'

module ProjectMediaSourceAssociations
  extend ActiveSupport::Concern

  def create_auto_tasks(team_tasks = [])
    team = self.team
    return if team.nil? || team.is_being_copied
    self.set_tasks_responses ||= {}
    team_tasks = self.team.auto_tasks(self.class.name) if team_tasks.blank?
    Task.bulk_insert(self.class.name, self.id, User.current&.id, team_tasks.pluck(:id), self.set_tasks_responses.to_h) unless team_tasks.empty?
  end

  def ordered_tasks(fieldset, associated_type = nil)
    associated_type ||= 'ProjectMedia'
    Task.where(annotation_type: 'task', annotated_type: associated_type, annotated_id: self.id).select{ |t| t.fieldset == fieldset }.sort_by{ |t| t.order || t.id || 0 }.to_a
  end

  def task_value(team_task_id, force = false)
    key = "#{self.class.name.underscore}:task_value:#{self.id}:#{team_task_id}"
    Rails.cache.fetch(key, force: force) do
      task = Task.where(annotation_type: 'task', annotated_type: self.class.name, annotated_id: self.id).select{ |t| t.team_task_id == team_task_id }.last
      task.nil? ? nil : task.first_response
    end
  end

  def respond_to_auto_tasks(ids, responses)
    # responses = { task_slug (string) => response (string) }
    Task.where(id: ids).find_each do |task|
      if responses.has_key?(task.slug)
        # task = Task.find(task.id)
        type = "task_response_#{task.type}"
        fields = {
          "response_#{task.type}" => responses[task.slug]
        }
        task.skip_check_ability = true
        task.response = { annotation_type: type, set_fields: fields.to_json }.to_json
        task.save!
      end
    end
  end
end
